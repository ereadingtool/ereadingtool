import requests
from uuid import uuid4
from typing import Dict

from requests.sessions import extract_cookies_to_jar

def dashboard_connect():
    def decorator(func):
        def synchronize(*args, **kwargs):
            protocol = "https://"
            base_url  = "api.languageflagshipdashboard.com"
            endpoint = "/api/userExists"
            params = {"email": "user_email@gmail.com"}
            resp = requests.get(protocol+base_url+endpoint, params)
            if resp.content == b'true':
                connected_to_dashboard = True
            else:
                connected_to_dashboard = False
            kwargs["connected_to_dashboard"] = connected_to_dashboard

            return func(*args, **kwargs)
        return synchronize
    return decorator


class DashboardData:
    def __init__(self, actor, result, verb, object):
        self.actor = actor
        self.result = result
        self.verb = verb
        self.object = object

    def to_dict(self) -> Dict:
        return {
            'activities': 'www.duckduckgo.com',
            'actor': self.actor,
            'id': str(uuid4()),
            'result': self.result,
            'verb': self.verb,
            'object': self.object,
            'verbs': ["http://adlnet.gov/expapi/verbs/completed"]
        }

# still need to get the text_readering answers...
class Actor:
    def __init__(self, name, mbox, object_type):
        self.name = name
        self.mbox = mbox
        self.object_type = object_type

    def to_dict(self) -> Dict:
        return {
            'name': self.name,
            'mbox': self.mbox,
            'objectType': self.object_type
        }

class Result:
    def __init__(self, score, state):
        self.score = score
        self.state = state

    def to_dict(self) -> Dict:
        return {
            'score': self.score,
            'completion': self.state,
            'success': 'true',
            'duration': 'PT85'
        }

class Verb:
    def to_dict(self) -> Dict:
        return {
            "id": "http://adlnet.gov/expapi/verbs/completed",
            "display": {
                "en": "completed"
                }
        }

class Object:
    def to_dict(self) -> Dict:
        return {
            "id": "http://star.com/some/url/for/the/quiz",   # base/text/TEXT_ID
            "definition": {
                "type": "http://adlnet.gov/expapi/activities/assessment",
                "name": {
                    "en": "Data transfer quiz"
                }
            },
            "objectType": "Activity"
        }
