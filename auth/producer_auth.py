import os
import time
import jwt
from channels.db import database_sync_to_async
from jwt.exceptions import InvalidTokenError
from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _  # TODO marked for deletion
from user.student.models import Student
from user.instructor.models import Instructor
from user.models import ReaderUser

async def jwt_validation(scope):
    """ Take JWT from query string to check the user against the db and validate its timestamp """
    if not scope['query_string']:
        return None
    # TODO: what if the user field is already populated
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
                user = jwt_decoded
                user['instructor'] = instructor
                user['is_authenticated'] = True
                return user
            else:
                # path error, same result
                raise InvalidTokenError
        except InvalidTokenError: 
            return None


class ProducerAuthMiddleware:
    """
    Custom middleware (insecure) that takes user IDs from the query string.
    """

    def __init__(self, inner):
        # Store the ASGI application we were passed
        self.inner = inner

    def __call__(self, scope):
        return ProducerAuthMiddlewareInstance(scope, self)


class ProducerAuthMiddlewareInstance:
    """
    Inner class that is instantiated once per scope.
    """

    def __init__(self, scope, middleware):
        self.middleware = middleware
        self.scope = dict(scope)
        self.inner = self.middleware.inner

    async def __call__(self, receive, send):
        """ Look up user from query string and validate their JWT. """

        self.scope['user'] = await jwt_validation(self.scope)
        
        if not self.scope['user'] or not self.scope['user'].is_authenticated:
            # TODO: The user has not be authenticated, 403?
            pass

        try:
            # Instantiate our inner application
            inner = self.inner(self.scope)
            return await inner(receive, send)
        except ValueError:
            # TODO: this seems to happen when there isn't a proper route. 404?
            pass