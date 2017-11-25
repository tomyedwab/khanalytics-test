import base64
import sendgrid
from sendgrid.helpers.mail import *
import sys
import os

import core.corelib.storage
import core.corelib.stage_runtime

# Get the parameters from the environment
runtime = core.corelib.stage_runtime.StageRuntime(sys.argv[1])

html = (
    core.corelib.storage
    .open(runtime.get_variable_value("html", "file"))
    .read()
    .decode("utf-8"))

from_email = runtime.get_variable_value("from_email", "constant")
to_email = runtime.get_variable_value("to_email", "constant")
subject = runtime.get_variable_value("subject", "constant")

with open("/var/credentials/sendgrid-api-key", "r") as f:
    SENDGRID_API_KEY = f.read().strip()

# Just take the contents of the <body> tag
html2 = "<html><body>" + html[html.index('<body>')+6:html.index('</body>')] + "</body></html>"

attachments = []

# Find embedded image data and extract it out into attachments
while True:
    try:
        idx1 = html2.index("<img src=\"data:")
        idx2 = html2[idx1+15:].index(";")
        idx3 = html2[idx1+15:].index("\"")
        type = html2[idx1+15:idx1+15+idx2]
        data = html2[idx1+15+idx2+8:idx1+15+idx3]

        attachment = Attachment()
        attachment.content = data
        attachment.type = type
        attachment.disposition = "inline"
        attachment.filename = "img-%04d.%s" % (len(attachments), type.split("/")[1])
        attachment.content_id = "img-%04d" % (len(attachments))
        attachments.append(attachment)

        html2 = html2[:idx1] + ("<img src=\"cid:%s\"" % attachment.content_id) + html2[idx1+15+idx3+1:]
    except ValueError:
        break

sg = sendgrid.SendGridAPIClient(apikey=SENDGRID_API_KEY)
mail = Mail(
    Email(from_email),
    subject,
    Email(to_email),
    Content("text/html", html2))
for attachment in attachments:
    mail.add_attachment(attachment)
response = sg.client.mail.send.post(request_body=mail.get())
print(response.status_code)
print(response.body)
print(response.headers)
