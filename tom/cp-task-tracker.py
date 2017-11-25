#!/usr/bin/env python3

from datetime import datetime, date
import httplib2
import json
import math
import os
import sys
import time
import urllib.request

from googleapiclient.discovery import build
import oauth2client.service_account
from google.cloud import storage

BIGQUERY_PROJECT_ID = "khanacademy.org:deductive-jet-827"
BIGQUERY_DATASET_ID = "tomyedwab"
BIGQUERY_TASKS_DATASET = "cp_support_tasks"
BIGQUERY_HISTORY_DATASET = "cp_support_history"
GCS_USER = "tom"
PERSONAL_KEY = None
ISO_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"
TEAM_ID = 253531696028551
DEBUG_ITEM = None


def format_date(d):
    return (d - datetime.utcfromtimestamp(0)).total_seconds()


def diff_days(diff):
    if diff:
        return diff.total_seconds() / (60 * 60 * 24)
    return None


def seconds_to_weeks(seconds):
    return math.floor((seconds / (60 * 60 * 24) - 4) / 7)


def weeks_to_seconds(weeks):
    return ((weeks * 7) + 4) * (60 * 60 * 24)


def api_call(uri):
    try:
        req = urllib.request.Request(
            f"https://app.asana.com/api/1.0/{uri}",
            headers={"Authorization": f"Bearer {PERSONAL_KEY}"})
        resp = urllib.request.urlopen(req)
        ret = json.loads(resp.read().decode('utf-8'))
        return ret["data"]
    except urllib.error.HTTPError:
        return None


def get_enum_value(task_data, enum_name):
    field = next(
        (field for field in task_data["custom_fields"]
            if field["name"] == enum_name),
        {"enum_value": None})
    return (field["enum_value"] or {}).get("name", "")


def list_projects():
    projects = {}
    current_type = "Other"
    for project in api_call(f"projects?team={TEAM_ID}"):
        if "===" in project["name"]:
            if "DAY TO DAYS" in project["name"]:
                current_type = "Project"
            elif "PARKING LOTS" in project["name"]:
                current_type = "Parking Lot"
            else:
                current_type = "Other"
            continue

        if "Incoming" in project["name"]:
            type = "Incoming"
        elif "Support Day-to-Day" in project["name"]:
            type = "Support"
        else:
            type = current_type

        projects[project["id"]] = {
            "name": project["name"],
            "type": type,
        }

    return projects


def load_task_ids(uri):
    try:
        return json.loads(
            core.corelib.storage
            .open(uri)
            .read()
            .decode("utf-8"))
    except Exception:
        return []


def save_task_ids(uri, task_ids):
    return (core.corelib.storage
        .open(uri)
        .write(json.dumps(task_ids).encode("utf-8")))


def load_project_task_ids(project_id):
    return {
        task["id"]
        for task in (api_call(f"projects/{project_id}/tasks") or [])
    }


class UnknownState(object):
    name = "Unknown"

    @staticmethod
    def enter(fsm, date):
        pass

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if event["type"] == "addToProject":
            if event["project"]["type"] == "Incoming":
                if fsm.prioritySet:
                    fsm.state = IncomingPrioritizedState
                else:
                    fsm.state = IncomingUnprioritizedState
                if not fsm.originatedFrom:
                    fsm.originatedFrom = "Incoming"

            elif event["project"]["type"] == "Support":
                fsm.state = SupportPriorityState
                if not fsm.originatedFrom:
                    fsm.originatedFrom = "Support"

            elif event["project"]["type"] == "Parking Lot":
                fsm.state = ParkingLotState
                if not fsm.originatedFrom:
                    fsm.originatedFrom = "Parking Lot"

            elif event["project"]["type"] == "Project":
                fsm.state = ProjectState
                if not fsm.originatedFrom:
                    fsm.originatedFrom = "Project"

            elif event["project"]["type"] == "Other":
                if not fsm.originatedFrom:
                    fsm.originatedFrom = "Other"
                fsm.idealPath = False

        if event["type"] == "setPriority":
            fsm.prioritySet = True
            return True

        if event["type"] == "completed":
            fsm.state = UnknownDoneState
            return True

        return True


class UnknownDoneState(object):
    name = "Done in unknown state"

    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredCompleted:
            fsm.enteredCompleted = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        # TODO: Reopened?
        return True


class IncomingState(object):
    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredIncoming:
            fsm.enteredIncoming = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if event["type"] == "addToProject":
            if event["project"]["type"] == "Incoming":
                return True

            if event["project"]["type"] == "Support":
                if fsm.state != IncomingPrioritizedState:
                    fsm.idealPath = False
                fsm.state = SupportPriorityState

            elif event["project"]["type"] == "Parking Lot":
                fsm.state = ParkingLotState

            elif event["project"]["type"] == "Project":
                fsm.state = ProjectState

            elif event["project"]["type"] == "Other":
                fsm.state = UnknownState
                fsm.idealPath = False

            else:
                return False

            return True

        if event["type"] == "movedToSection":
            return True

        if event["type"] == "completed":
            fsm.state = SupportDoneState
            return True

        return False


class IncomingUnprioritizedState(object):
    name = "Incoming (Unprioritized)"

    @staticmethod
    def enter(fsm, date):
        IncomingState.enter(fsm, date)

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if IncomingState.run(fsm, event):
            return True

        if event["type"] == "setPriority":
            fsm.prioritySet = True
            fsm.state = IncomingPrioritizedState
            return True

        return False


class IncomingPrioritizedState(object):
    name = "Incoming (Prioritized)"

    @staticmethod
    def enter(fsm, date):
        IncomingState.enter(fsm, date)

        if not fsm.enteredPrioritized:
            fsm.enteredPrioritized = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if IncomingState.run(fsm, event):
            return True

        if event["type"] == "setPriority":
            fsm.prioritySet = True
            return True

        return False


class SupportState(object):
    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredSupport:
            fsm.enteredSupport = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if event["type"] == "addToProject":
            if event["project"]["type"] == "Parking Lot":
                fsm.state = ParkingLotState

            elif event["project"]["type"] == "Project":
                fsm.state = ProjectState

            elif event["project"]["type"] == "Incoming":
                if fsm.prioritySet:
                    fsm.state = IncomingPrioritizedState
                else:
                    fsm.state = IncomingUnprioritizedState
                fsm.idealPath = False

            elif event["project"]["type"] == "Other":
                fsm.state = UnknownState
                fsm.idealPath = False

            else:
                return False

            return True

        if event["type"] == "movedToSection":
            if event["section"] in ["Accepted", "In Progress", "Development", "Review", "Deployment", "Deploy", "Test"]:
                fsm.state = SupportAcceptedState
                return True
            if event["section"] in ["Waiting for more info", "Waiting on Something/Review"]:
                fsm.state = SupportWaitingState
                return True
            if event["section"] in ["Done", "Done!"]:
                fsm.state = SupportDoneState
                return True
            if event["section"] == "Priority":
                if fsm.state != SupportPriorityState:
                    fsm.idealPath = False
                fsm.state = SupportPriorityState
                return True

        if event["type"] == "completed":
            fsm.state = SupportDoneState
            return True


class SupportPriorityState(object):
    name = "Support (Priority)"

    @staticmethod
    def enter(fsm, date):
        SupportState.enter(fsm, date)

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if SupportState.run(fsm, event):
            return True

        return False


class SupportAcceptedState(object):
    name = "Support (Accepted)"

    @staticmethod
    def enter(fsm, date):
        SupportState.enter(fsm, date)

        if not fsm.enteredAccepted:
            fsm.enteredAccepted = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if SupportState.run(fsm, event):
            return True

        return False


class SupportWaitingState(object):
    name = "Support (Waiting)"

    @staticmethod
    def enter(fsm, date):
        SupportState.enter(fsm, date)

        fsm.enteredWaiting = date

    @staticmethod
    def exit(fsm, date):
        fsm.waitingTime = fsm.waitingTime + (date - fsm.enteredWaiting).days
        fsm.enteredWaiting = None

    @staticmethod
    def run(fsm, event):
        if SupportState.run(fsm, event):
            return True

        return False


class SupportDoneState(object):
    name = "Done in Support"

    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredCompleted:
            fsm.enteredCompleted = date
            fsm.completedInSupport = True

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        # TODO: Reopened?
        return True


class ParkingLotState(object):
    name = "Parking lot"

    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredParkingLot:
            fsm.enteredParkingLot = date

        # Consider parking lot tasks "prioritized"
        if not fsm.enteredPrioritized:
            fsm.enteredPrioritized = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if event["type"] == "addToProject":
            if event["project"]["type"] == "Support":
                fsm.state = SupportPriorityState

            elif event["project"]["type"] == "Parking Lot":
                pass

            elif event["project"]["type"] == "Project":
                fsm.state = ProjectState

            elif event["project"]["type"] == "Incoming":
                if fsm.prioritySet:
                    fsm.state = IncomingPrioritizedState
                else:
                    fsm.state = IncomingUnprioritizedState
                fsm.idealPath = False

            elif event["project"]["type"] == "Other":
                fsm.state = UnknownState
                fsm.idealPath = False

            else:
                return False

            return True

        if event["type"] == "completed":
            fsm.state = ProjectDoneState
            return True

        if event["type"] == "movedToSection":
            return True


class ProjectState(object):
    name = "Project"

    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredProject:
            fsm.enteredProject = date

        # Consider project tasks "prioritized"
        if not fsm.enteredPrioritized:
            fsm.enteredPrioritized = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        if event["type"] == "addToProject":
            if event["project"]["type"] == "Support":
                fsm.state = SupportPriorityState

            elif event["project"]["type"] == "Parking Lot":
                fsm.state = ParkingLotState

            elif event["project"]["type"] == "Project":
                pass

            elif event["project"]["type"] == "Incoming":
                if fsm.prioritySet:
                    fsm.state = IncomingPrioritizedState
                else:
                    fsm.state = IncomingUnprioritizedState
                fsm.idealPath = False

            elif event["project"]["type"] == "Other":
                fsm.state = UnknownState
                fsm.idealPath = False

            else:
                return False

            return True

        if event["type"] == "completed":
            fsm.state = ProjectDoneState
            return True

        if event["type"] == "setPriority":
            fsm.prioritySet = True
            return True

        if event["type"] == "movedToSection":
            return True


class ProjectDoneState(object):
    name = "Done in project"

    @staticmethod
    def enter(fsm, date):
        if not fsm.enteredCompleted:
            fsm.enteredCompleted = date

    @staticmethod
    def exit(fsm, date):
        pass

    @staticmethod
    def run(fsm, event):
        # TODO: Reopened?
        return True


class TaskFSM(object):
    def __init__(self, task_id):
        self.state = UnknownState
        self.idealPath = True
        self.originatedFrom = None
        self.enteredIncoming = None
        self.enteredPrioritized = None
        self.enteredSupport = None
        self.enteredAccepted = None
        self.enteredParkingLot = None
        self.enteredProject = None
        self.enteredCompleted = None
        self.completedInSupport = False
        self.enteredWaiting = None
        self.waitingTime = 0
        self.prioritySet = False
        self.task_id = task_id

    def run(self, event):
        oldState = self.state
        handled = self.state.run(self, event)

        if not handled:
            raise Exception("Event %s not handled in state %s (task %s)" % (
                event, self.state, self.task_id))
        elif DEBUG_ITEM:
            print("Event: %s\nState: %s\n" % (event, self.__dict__))

        if oldState != self.state:
            oldState.exit(self, event["date"])
            self.state.enter(self, event["date"])

    def serialize(self):
        today = date.today()

        prioritizationTime = None
        if self.enteredIncoming and self.enteredPrioritized:
            prioritizationTime = (self.enteredPrioritized - self.enteredIncoming).days
        elif self.enteredIncoming and self.enteredCompleted:
            prioritizationTime = (self.enteredCompleted - self.enteredIncoming).days
        elif self.enteredIncoming:
            prioritizationTime = (today - self.enteredIncoming).days

        toSortTime = 99999
        if self.enteredIncoming and self.enteredSupport:
            toSortTime = min(toSortTime, (self.enteredSupport - self.enteredIncoming).days)
        if self.enteredIncoming and self.enteredParkingLot:
            toSortTime = min(toSortTime, (self.enteredParkingLot - self.enteredIncoming).days)
        if self.enteredIncoming and self.enteredProject:
            toSortTime = min(toSortTime, (self.enteredProject - self.enteredIncoming).days)
        if self.enteredIncoming and self.enteredCompleted:
            toSortTime = min(toSortTime, (self.enteredCompleted - self.enteredIncoming).days)

        if toSortTime == 99999:
            if self.enteredIncoming:
                toSortTime = (today - self.enteredIncoming).days
            else:
                toSortTime = None

        toAcceptTime = None
        if self.enteredAccepted and self.enteredSupport:
            toAcceptTime = (self.enteredAccepted - self.enteredSupport).days
        elif self.enteredSupport:
            toAcceptTime = (today - self.enteredSupport).days

        timeInSupport = None
        if self.enteredCompleted and self.enteredSupport:
            timeInSupport = (self.enteredCompleted - self.enteredSupport).days
        elif self.enteredSupport:
            totalTime = (today - self.enteredSupport).days

        totalTime = None
        if self.enteredCompleted and self.enteredIncoming:
            totalTime = (self.enteredCompleted - self.enteredIncoming).days
        elif self.enteredCompleted and self.enteredSupport:
            totalTime = (self.enteredCompleted - self.enteredSupport).days
        elif self.enteredIncoming:
            totalTime = (today - self.enteredIncoming).days
        elif self.enteredSupport:
            totalTime = (today - self.enteredSupport).days

        waitingTime = self.waitingTime
        if self.enteredWaiting:
            waitingTime = self.waitingTime + (today - self.enteredWaiting).days

        return {
            "currentState": self.state.name,
            "originatedFrom": self.originatedFrom,
            "idealPath": self.idealPath,
            "prioritizationTime": prioritizationTime,
            "toSortTime": toSortTime,
            "toAcceptTime": toAcceptTime,
            "timeInSupport": timeInSupport,
            "waitingTime": waitingTime,
            "totalTime": totalTime,
        }


def process_task_history(projects, task_id, task_priority):
    task_history = api_call(f"tasks/{task_id}/stories")
    if not task_history:
        print(f"Couldn't load history for task {task_id}!")
        return None

    if DEBUG_ITEM:
        print(f"### TASK {task_id} ###")

    events = []
    priority_set = False
    current_project = None

    for entry in task_history:
        if entry["type"] == "comment":
            continue
        if entry["type"] != "system":
            continue

        entry_date = datetime.strptime(entry["created_at"], ISO_FORMAT).date()

        for project in projects.values():
            project_name = project["name"]
            if entry["text"] == f"added to {project_name}":
                events.append({
                    "type": "addToProject",
                    "project": project,
                    "date": entry_date,
                })
                current_project = project_name

        if entry["text"].startswith("set Priority to"):
            events.append({
                "type": "setPriority",
                "priority": entry["text"].split("\"")[1],
                "date": entry_date,
            })
            priority_set = True

        elif (entry["text"].startswith("moved from") or
                entry["text"].startswith("moved this Task from")):
            section = entry["text"][entry["text"].rindex("to ") + 3:]
            if " in " in section:
                idx = section.rindex(" in ")
                in_project = section[idx + 4:]
                section = section[:idx]
            if section[-1] == ")":
                idx = section.rindex(" (")
                in_project = section[idx + 2:-1]
                section = section[:idx]
            else:
                in_project = None

            if not in_project or in_project == current_project:
                events.append({
                    "type": "movedToSection",
                    "section": section,
                    "date": entry_date,
                })

        elif (entry["text"] == "completed this task" or
              entry["text"] == "marked this task complete" or
              entry["text"].startswith("marked this a duplicate")):
            events.append({
                "type": "completed",
                "date": entry_date,
            })

    if not priority_set and task_priority != "":
        # Sometimes the task has a priority but we don't find any evidence in
        # the history; insert a synthetic event at the beginning for it
        events.insert(0, {
            "type": "setPriority",
            "priority": task_priority,
            "date": events[0]["date"],
        })

    fsm = TaskFSM(task_id)
    for event in events:
        fsm.run(event)

    return fsm.serialize()


def get_task_info(projects, task_id):
    task_data = api_call(f"tasks/{task_id}")
    if not task_data:
        return None
    if task_data["name"].endswith(":"):
        return None

    project_name = None
    project_type = None
    project_section = None
    for membership in task_data["memberships"]:
        if membership["project"]["id"] in projects:
            project_name = projects[membership["project"]["id"]]["name"]
            project_type = projects[membership["project"]["id"]]["type"]
            project_section = (membership["section"] or {}).get("name", "")

    task_info = {
        "id": task_data["id"],
        "today": today,
        "name": task_data["name"],
        "assignee": (task_data["assignee"] or {}).get("name", None),
        "completed": (format_date(datetime.strptime(
                      task_data["completed_at"], ISO_FORMAT))
                      if task_data["completed"] else None),
        "created": format_date(
            datetime.strptime(task_data["created_at"], ISO_FORMAT)),
        "type": get_enum_value(task_data, "Type"),
        "severity": get_enum_value(task_data, "Severity (QA)"),
        "priority": get_enum_value(task_data, "Priority"),
        "projectName": project_name,
        "projectType": project_type,
        "projectSection": project_section,
    }
    return task_info


# Main body
if __name__ == "__main__":
    # Get the parameters from the environment
    if sys.argv[1] == "-":
        task_ids_uri = None
        output_uri = None
        task_ids = set()
        if len(sys.argv) > 2:
            DEBUG_ITEM = sys.argv[2]
    else:
        import core.corelib.storage
        import core.corelib.stage_runtime
        runtime = core.corelib.stage_runtime.StageRuntime(sys.argv[1])
        task_ids_uri = runtime.get_variable_value("task_ids", "file")
        output_uri = runtime.get_variable_value("output", "file")
        task_ids = set(load_task_ids(task_ids_uri))
        print("Loaded %d task IDs from previous run" % len(task_ids))

    with open("/var/credentials/asana-personal-key", "r") as f:
        PERSONAL_KEY = f.read().strip()

    today = format_date(datetime.utcnow())
    current_week = seconds_to_weeks(today)

    projects = list_projects()

    existing_task_ids = set(task_ids)

    if DEBUG_ITEM:
        task_ids = [DEBUG_ITEM]
    else:
        for project_id in projects.keys():
            if projects[project_id]["type"] == "Other":
                continue
            new_tasks = load_project_task_ids(project_id)
            print("Loaded %d task IDs from project %s" %
                  (len(new_tasks), projects[project_id]["name"]))
            task_ids = task_ids | new_tasks

    print("Processing %d task IDs (%d new)" % (
        len(task_ids), len(set(task_ids) - set(existing_task_ids))))
    if task_ids_uri:
        save_task_ids(task_ids_uri, list(task_ids))

    task_rows = []
    for idx, task_id in enumerate(list(task_ids)):
        task_info = get_task_info(projects, task_id)
        if not task_info:
            continue

        history_props = process_task_history(
            projects, task_id, task_info["priority"])
        if not history_props:
            continue

        task_info.update(history_props)

        task_rows.append(json.dumps(task_info))
        print("Processed %d/%d tasks" % (idx + 1, len(task_ids)))

        if DEBUG_ITEM:
            print(task_info)

    if output_uri:
        print("Writing to %s..." % output_uri)
        (core.corelib.storage
            .open(output_uri)
            .write("\n".join(task_rows).encode("utf-8")))
