import json
import os
import time
import jwt
from typing import Dict
from jwt.exceptions import InvalidTokenError
from user.student.models import Student
from user.instructor.models import Instructor
from django.http import HttpResponse

def jwt_valid(status: int, errors: Dict):
    def decorator(func):
        def validate(*args, **kwargs):
            secret_key = os.getenv('DJANGO_SECRET_KEY')
            scope = args[0].request.scope
            meta = args[0].request.META
            if scope['query_string']:
                jwt_encoded = scope['query_string'][6:] if scope['query_string'][:6] == b'token=' else scope['query_string']
            else:
                jwt_encoded = meta['HTTP_AUTHORIZATION'][7:] if meta['HTTP_AUTHORIZATION'][:7] == 'Bearer ' else meta['HTTP_AUTHORIZATION']
            try:
                jwt_decoded = jwt.decode(jwt_encoded, secret_key, algorithms=['HS256'])

                if jwt_decoded['exp'] <= time.time():
                    # then their token has expired 
                    return HttpResponse(status=status)

                # These cases handle incrementing bugs that could arise from a stolen jwt 
                # being applied to a different user's profile.
                if kwargs['pk']:
                    # user_id is unique across the DB
                    if Student.objects.filter(user_id=jwt_decoded['user_id']):
                        # force evaluation of the QuerySet. We already know it contains at least one element
                        student = list(Student.objects.filter(user_id=jwt_decoded['user_id']))[0]
                        if student == None or student.pk != kwargs['pk']:
                            return  HttpResponse(status=status)
                    elif Instructor.objects.filter(user_id=jwt_decoded['user_id']):
                        instructor = list(Instructor.objects.filter(user_id=jwt_decoded['user_id']))[0]
                        if instructor == None or instructor.pk != kwargs['pk']:
                            return HttpResponse(status=status)
                    else:
                        # they're neither an instructor or a student
                        return HttpResponse(status=status)
            except: 
                return HttpResponse(status=status)
    
            return func(*args, **kwargs)
        return validate
    return decorator

    