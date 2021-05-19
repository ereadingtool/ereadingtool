from .dashboard import DashboardActor, DashboardData, DashboardObject, DashboardResult, DashboardVerb, dashboard_connected
from ereadingtool import settings
import json
import requests
import os


# function called because the update interval has been reached
# TODO: decorate with dashboard_connected() just in case

@dashboard_connected()
def sync_on_login(student, **kwargs):
    try:
        report = json.dumps(student.performance.to_dict())

        actor = DashboardActor(student.user.first_name + " " + student.user.last_name,
                      student.user.email,
                      "Agent"
        ).to_dict()
        # TODO: find something better than `score` to pass more data
        score = {
            # "raw": report,
            "raw": 4,
            "min": 0,
            "max": 5,
            "scaled": 0
        }

        result = DashboardResult(score, '').to_dict()
        verb = DashboardVerb().to_dict()
        object = DashboardObject().to_dict()

        dashboard_data = DashboardData(actor, result, verb, object).to_dict()

        endpoint = settings.DASHBOARD_LRS_ENDPOINT + "/data/xAPI/statements?statementId=" + dashboard_data['id']
        headers = {
            'X-Experience-API-Version' : '1.0.3',
            'Content-Type' : 'application/json',
            'Authorization' : os.getenv("DASHBOARD_TOKEN")
        }

        requests.put(endpoint, headers=headers, data=json.dumps(dashboard_data))

    except Exception as e:
        # TODO: handle this error
        pass
    pass