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

            if hasattr(args[0].request, 'scope'):
                # WSGI
                jwt_encoded = args[0].request.headers._store['authorization'][1]
            else:
                # ASGI
                meta = args[0].request.META
                jwt_encoded = meta['HTTP_AUTHORIZATION'][7:] if meta['HTTP_AUTHORIZATION'][:7] == 'Bearer ' else meta['HTTP_AUTHORIZATION']
            
            # If any sort of ValueError or database access error occurs then we bail.
            try:
                jwt_decoded = jwt.decode(jwt_encoded, secret_key, algorithms=['HS256'])

                if jwt_decoded['exp'] <= time.time():
                    # then their token has expired 
                    return HttpResponse(status=status, content=errors)

            except: 
                return HttpResponse(status=status, content=errors)

            return func(*args, **kwargs)
        return validate
    return decorator

    