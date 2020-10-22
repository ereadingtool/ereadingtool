import os
import time
import jwt
from jwt.exceptions import InvalidTokenError
from user.student.models import Student
from user.instructor.models import Instructor

def jwt_validation(scope):
    """ Take JWT from query string to check the user against the db and validate its timestamp """
    if not scope['query_string']:
        return None
    else:
        secret_key = os.getenv('DJANGO_SECRET_KEY')
        try:
            jwt_decoded = jwt.decode(scope['query_string'], secret_key, algorithms=['HS256'])

            if jwt_decoded['exp'] <= time.time():
                # then their token has expired 
                raise InvalidTokenError

            if "student/text_read/" in scope['path']:
                if not Student.objects.filter(user_id=jwt_decoded['user_id']):
                    # then there is no user in the QuerySet
                    raise InvalidTokenError
                # force evaluation of the QuerySet. We already know it contains at least one element
                student = list(Student.objects.filter(user_id=jwt_decoded['user_id']))[0]

                # TODO: there may be need to make user an object and have the student object be a member
                return student.user
            elif "instructor/text_read/" in scope['path']:
                if not Instructor.objects.filter(user_id=jwt_decoded['user_id']):
                     # then there is no user in the QuerySet
                     raise InvalidTokenError
                # force evaluation of the QuerySet. We already know it contains at least one element
                instructor = list(Instructor.objects.filter(user_id=jwt_decoded['user_id']))[0]

                # TODO: there may be need to make user an object and have the student object be a member
                return instructor.user
            else:
                # path error, same result
                raise InvalidTokenError
        except InvalidTokenError: 
            return None