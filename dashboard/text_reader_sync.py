import requests
import json
from uuid import uuid4
from .dashboard import Actor, DashboardData, Object, Result, Verb

def dashboard_synchronize_text_reading(text_reading):
    user_email = text_reading.student.user.email
    protocol = "https://"
    base_url  = "api.languageflagshipdashboard.com"
    endpoint = "/api/userExists"
    params = {"email": user_email}
    resp = requests.get(protocol+base_url+endpoint, params)
    if resp.content == b'true':
        actor = Actor(text_reading.student.user.first_name + " " + text_reading.student.user.last_name,
                      text_reading.student.user.email,
                      "Agent"
        ).to_dict()
        score = {
			"raw": text_reading.score['section_scores'],
			"min": 0,
			"max": text_reading.score['possible_section_scores'],
			"scaled": 1
        }
        result = Result(score, text_reading.state).to_dict()
        verb = Verb().to_dict()
        object = Object().to_dict()

        dashboard_data = json.dumps(DashboardData(actor, result, verb, object).to_dict())

        # endpoint = "http://127.0.0.1:5000"
        endpoint = "http://lrs.languageflagshipdashboard.com/data/xAPI/statements?statementId=" + str(uuid4())
        headers = {
            'X-Experience-API-Version' : '1.0.3',
            'Content-Type' : 'application/json' 
        }

        try:
            resp = requests.put(endpoint, headers=headers, data=dashboard_data)
        except Exception as e:
            pass

        return
    else:
        return