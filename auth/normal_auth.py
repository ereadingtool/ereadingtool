import os
import time
import jwt
from typing import Dict
from user.student.models import Student
from user.instructor.models import Instructor
from django.http import HttpResponse
from urllib.parse import parse_qs

def jwt_valid(status: int, errors: str):
    def decorator(func):
        def validate(*args, **kwargs):
            secret_key = os.getenv('DJANGO_SECRET_KEY')

            try:
                if hasattr(args[0].request, 'scope'):
                    jwt_encoded_dirty = args[0].request.headers._store['authorization'][1]
                else:
                    meta = args[0].request.META
                    jwt_encoded_dirty = meta['HTTP_AUTHORIZATION']

                jwt_encoded = jwt_encoded_dirty[7:] if 'Bearer ' == jwt_encoded_dirty[:7] else jwt_encoded_dirty

                jwt_decoded = jwt.decode(jwt_encoded, secret_key, algorithms=['HS256'])

                if jwt_decoded['exp'] <= time.time():
                    return HttpResponse(status=status, content=errors)

            except: 
                return HttpResponse(status=status, content=errors)

            return func(*args, **kwargs)
        return validate
    return decorator

    