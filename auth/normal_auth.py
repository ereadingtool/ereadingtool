import json
import os
import time
import jwt
from typing import Dict
from jwt.exceptions import InvalidTokenError
from user.student.models import Student
from user.instructor.models import Instructor
from django.http import HttpResponse

def jwt_validation(scope):
    """ Take JWT from query string to check the user against the db and validate its timestamp """
    if not scope['query_string']:
        return None
    else:
        secret_key = os.getenv('DJANGO_SECRET_KEY')
        try:
            qs = scope['query_string'][6:] if scope['query_string'][:6] == b'token=' else scope['query_string']
            jwt_decoded = jwt.decode(qs, secret_key, algorithms=['HS256'])

            if jwt_decoded['exp'] <= time.time():
                # then their token has expired 
                raise InvalidTokenError

            if "performance_report.pdf" in scope['path']:
                if not Student.objects.filter(user_id=jwt_decoded['user_id']):
                    # then there is no user in the QuerySet
                    raise InvalidTokenError
                # force evaluation of the QuerySet. We already know it contains at least one element
                student = list(Student.objects.filter(user_id=jwt_decoded['user_id']))[0]

                return student
            else:
                # path error, same result
                raise InvalidTokenError
        except InvalidTokenError: 
            return None


def jwt_valid(status: int, errors: Dict):
    def decorator(func):
        def validate(*args, **kwargs):
            if not args[0].request.scope['query_string']:
                return HttpResponse(json.dumps(errors), status=status)
            else:
                secret_key = os.getenv('DJANGO_SECRET_KEY')
                scope = args[0].request.scope
                try:
                    qs = scope['query_string'][6:] if scope['query_string'][:6] == b'token=' else scope['query_string']
                    jwt_decoded = jwt.decode(qs, secret_key, algorithms=['HS256'])

                    if jwt_decoded['exp'] <= time.time():
                        # then their token has expired 
                        return HttpResponse(status=status)

                except: 
                    return HttpResponse(status=status)
    
            return func(*args, **kwargs)
        return validate
    return decorator

    