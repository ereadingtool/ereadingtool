import os
import jwt
from channels.db import database_sync_to_async
from jwt.exceptions import InvalidTokenError
from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _

# from os import getenv # why doesn't this work?
# from jwt import decode # or this?

# Temporary parsing function
# TODO: Would this need to be async?
async def temp_parse_qs(qs):
    """ This function exists because the `query_string` still contains some of the URL """
    new_qs = b''
    for i in range(0, len(qs)):
        if chr(qs[-i]) == '/':
            new_qs = qs[:-i]

    return new_qs


# {
#   "typ": "JWT",
#   "alg": "HS256"
# }
# {
#   "user_id": 149,
#   "email": "jeffreydelamare@gmail.com",
#   "username": "jeffreydelamare@gmail.com",
#   "exp": 1600976678
# }
# secret key is DJANGO_SECRET_KEY
async def jwt_validation(query_string):
    # create a method to validate the jwt
    if not query_string:
        # Then the querystring is empty
        pass
    else:
        query_string = await temp_parse_qs(query_string[6:])
        secret_key = os.getenv('DJANGO_SECRET_KEY')
        try:
            jwt_decoded = jwt.decode(query_string, secret_key, algorithms=['HS256'])
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


        # TODO: Validate JWT here
            # if the jwt is valid set that is_authenticated to True
            # else the user is not authenticated 
                # they should be directed to login again
                # their token should be reset
        # Instantiate our inner application
        try:
            inner = self.inner(self.scope)
        except ValueError:
            pass

        return await inner(receive, send)