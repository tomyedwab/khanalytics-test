# participants in all current growth experiments
## Destination: cathleen.growth_experiment_participants
SELECT
      rounds.bingo_id as bingo_id,
      rounds,
      experiment,
      alternative,
      round_participation_time,
      experiment_participation_time,
FROM (
    # select all bingo_id selected into growth experiment rounds
    SELECT
       bingo_id,
       alternative as rounds,
       SEC_TO_TIMESTAMP(INTEGER(participation_time)) as round_participation_time
    FROM [bigbingo.source_participants]
    WHERE experiment='growth_experiments'
) as rounds
INNER JOIN (
    # join to specific experiment participation
    SELECT
       bingo_id,
       experiment,
       alternative,
       SEC_TO_TIMESTAMP(INTEGER(participation_time)) as experiment_participation_time
    FROM [bigbingo.source_participants]
    # a/b test experiments, not the one for growth rounds
    # used to determine growth round
    WHERE experiment!='growth_experiments'
) as experiments
  ON rounds.bingo_id = experiments.bingo_id
# only include experiments that started after the learner
# added into the experiment rounds
WHERE experiment_participation_time >= round_participation_time
