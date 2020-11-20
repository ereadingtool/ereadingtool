import os
import time
import jwt
import json 
from django.http import HttpResponse
from django.core.handlers.wsgi import WSGIRequest
from channels.http import AsgiRequest
from jwt import InvalidTokenError

def jwt_valid():
    def decorator(func):
        def validate(*args, **kwargs):
            try:
                secret_key = os.getenv('DJANGO_SECRET_KEY')
                request = None
                for e in args:
                    if isinstance(e, AsgiRequest):
                        request = e
                    elif isinstance(e, WSGIRequest):
                        request = e

                if not request: 
                    raise InvalidTokenError 

                jwt_encoded_dirty = request.META['HTTP_AUTHORIZATION']

                jwt_encoded = jwt_encoded_dirty[7:] if 'Bearer ' == jwt_encoded_dirty[:7] else jwt_encoded_dirty

                jwt_decoded = jwt.decode(jwt_encoded, secret_key, algorithms=['HS256'])

                if jwt_decoded['exp'] <= time.time():
                    raise InvalidTokenError

            except InvalidTokenError as e: 
                return HttpResponse(status=403, content=json.dumps({'error': 'Invalid token'}), content_type="application/json")

            return func(*args, **kwargs)
        return validate
    return decorator