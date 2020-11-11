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

                # These cases handle incrementing bugs that could arise from a stolen jwt 
                # being applied to a different user's profile.
                if 'pk' in kwargs:
                    # user_id is unique across the DB
                    if Student.objects.filter(user_id=jwt_decoded['user_id']):
                        # force evaluation of the QuerySet. We already know it contains at least one element
                        student = list(Student.objects.filter(user_id=jwt_decoded['user_id']))[0]
                        if student == None or student.pk != kwargs['pk']:
                            return  HttpResponse(status=status, content=errors)
                    elif Instructor.objects.filter(user_id=jwt_decoded['user_id']):
                        instructor = list(Instructor.objects.filter(user_id=jwt_decoded['user_id']))[0]
                        if instructor == None or instructor.pk != kwargs['pk']:
                            return HttpResponse(status=status, content=errors)
                    else:
                        # they're neither an instructor or a student
                        return HttpResponse(status=status, content=errors)
            except: 
                return HttpResponse(status=status, content=errors)

            return func(*args, **kwargs)
        return validate
    return decorator

    