import os
import jwt
from channels.db import database_sync_to_async
from jwt.exceptions import InvalidTokenError
from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _

# TODO: return type should be all things user related that are valid or a `None` indicating a redirect to login
async def jwt_validation(query_string):
    # create a method to validate the jwt
    if not query_string:
        # Then the querystring is empty
        pass
    else:
        #query_string = await temp_parse_qs(query_string[6:])
        secret_key = os.getenv('DJANGO_SECRET_KEY')
        try:
            jwt_decoded = jwt.decode(query_string, secret_key, algorithms=['HS256'])

            # TODO: check the database to confirm that the username exists both student and instructor fields
            # TODO: check the time to confirm it hasn't expired
            # TODO: return {'is_authenticated': <BOOL>, 'pk': <USER_ID?>}
            return jwt_decoded
        except InvalidTokenError: 
            return None
            pass
            # Token is not valid

    # TODO: make exception that jwt is invalid
        # return AnonymousUser()


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
        # Look up user from query string (you should also do things like
        # checking if it is a valid user ID, or if scope["user"] is already
        # populated).
        # TODO: Recreate the user object since that'll be needed by base.py
        self.scope['user'] = await jwt_validation(self.scope["query_string"])
        if not self.scope['user']:
            # TODO: The user has not be authenticated, 403?
            pass

        # TODO: Validate JWT here
            # if the jwt is valid set that is_authenticated to True
            # else the user is not authenticated 
                # they should be directed to login again
                # their token should be reset
        # TODO: There's an issue here, need to add `/student/text_read/<int>/` to the `scope['path']`
        # Instantiate our inner application
        try:
            self.scope['user']['is_authenticated'] = True
            inner = self.inner(self.scope)
            return await inner(receive, send)
        except ValueError:
            pass
            # TODO: this seems to happen when there isn't a proper route. 404?
