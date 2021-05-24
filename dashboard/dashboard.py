import requests
from uuid import uuid4
from typing import Dict



# decorator used to see if a user is connected to the dashboard
def dashboard_connected():
    def decorator(func):
        def synchronize(*args, **kwargs):
            protocol = "https://"
            base_url  = "api.languageflagshipdashboard.com"
            endpoint = "/api/userExists"
            cached_dashboard_connection = False
            try:
                params = {"email": args[0].user.email}
                cached_dashboard_connection = args[0].user.student.connected_to_dashboard
            except:
                try:
                    params = {"email": args[0].student.user.email}
                    cached_dashboard_connection = args[0].student.connected_to_dashboard
                except:
                    # not sure we can get here
                    params = {"email": ""}
                    connected_to_dashboard = False
                    kwargs["connected_to_dashboard"] = connected_to_dashboard
                    return func(*args, **kwargs)

            if not cached_dashboard_connection:
                resp = requests.get(protocol+base_url+endpoint, params)
                if resp.content == b'true':
                    connected_to_dashboard = True
                else:
                    connected_to_dashboard = False
            else:
                connected_to_dashboard = True

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
            'id': str(uuid4()),
            'actor': self.actor,
            'result': self.result,
            'verb': self.verb,
            'object': self.object,
        }

class DashboardActor:
    def __init__(self, name, mbox, object_type):
        self.name = name
        self.mbox = mbox
        self.object_type = object_type

    def to_dict(self) -> Dict:
        return {
            'name': self.name,
            'mbox': 'mailto:' + self.mbox,
            'objectType': self.object_type
        }

# What does this result share in common with the others?
class DashboardResult:
    NotImplemented


class DashboardResultMyWords(DashboardResult):
    NotImplemented

class DashboardResultTextComplete:
    def __init__(self, score, state):
        self.score = score
        if state == 'complete':
            self.state = True
        else:
            self.state = False

    def to_dict(self) -> Dict:
        return {
            'score': self.score,
            'completion': self.state,
            'success': True,
        }


class DashboardVerb:
    def to_dict(self) -> Dict:
        return {
            "id": "http://adlnet.gov/expapi/verbs/completed",
            "display": {
                "en": "completed"
                }
        }

class DashboardObject:
    def __init__(self, url=''):
        try:
            self.url = url
        except:
            self.url = ''

    def set_object_url(self, url):
        self.url = url

    def to_dict(self) -> Dict:
        return {
            "id": self.url,
            "definition": {
                "type": "http://adlnet.gov/expapi/activities/assessment",
                "name": {
                    "en": "Data transfer quiz"
                }
            },
            "objectType": "Activity"
        }
