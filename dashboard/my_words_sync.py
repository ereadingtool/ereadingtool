import requests
import json
import os
from ereadingtool.settings import DASHBOARD_STAR_ENDPOINT
from .dashboard import DashboardActor, DashboardData, DashboardObject, DashboardResult, DashboardVerb
from .dashboard import dashboard_connected


@dashboard_connected()
def dashboard_synchronize_my_words(student, text_phrase, text_section, **kwargs):
    # Contemplating an exception here, what would it be?
    if not kwargs['connected_to_dashboard']:
        return
    else:
        # What kind of data do we want to pass to the LRS here?

        # Same stuff that is provided to the My Words...

        # score = {
        #     "raw":
        #     "min": 0,
        #     "max":
        #     "scaled": 1
        # }
        actor = DashboardActor(student.user.first_name + " " + student.user.last_name,
                    student.user.email,
                    "Agent"
        ).to_dict()
        # result = DashboardResult(score, text_reading.state).to_dict()

        # TODO
        verb = DashboardVerb().to_dict()
        text_url = DASHBOARD_STAR_ENDPOINT + "/text/" + str(text_reading.text.id)
        object = DashboardObject(url=text_url).to_dict()
        dashboard_data = DashboardData(actor, result, verb, object).to_dict()

        endpoint =  + dashboard_data['id']
        headers = {
            'X-Experience-API-Version' : '1.0.3',
            'Content-Type' : 'application/json',
            'Authorization' : os.getenv("DASHBOARD_TOKEN")
        }

        requests.put(endpoint, headers=headers, data=json.dumps(dashboard_data))