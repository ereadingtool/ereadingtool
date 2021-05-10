import requests

def dashboard_connect():
    def decorator(func):
        def synchronize(*args, **kwargs):
            protocol = "https://"
            base_url  = "api.languageflagshipdashboard.com"
            endpoint = "/api/userExists"
            params = {"email": "user_email@gmail.com"}
            resp = requests.get(protocol+base_url+endpoint, params)
            if resp.content == b'true':
                is_dashboard_user = True
            else:
                is_dashboard_user = False
            kwargs["is_dashboard_user"] = is_dashboard_user

            return func(*args, **kwargs)
        return synchronize
    return decorator