from channels.db import database_sync_to_async

# TODO: Determine if this is even necessary. Where would a User object come from?
# It seems entirely too bloated.
# @database_sync_to_async
# def get_user(user_id):
#     try:
#         return User.objects.get(id=user_id)
#     except User.DoesNotExist:
#         return AnonymousUser()

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
        print("test")
        # self.scope['user'] = await get_user(int(self.scope["query_string"]))

        # TODO: Validate JWT here
        # TODO: Recreate the user object since that'll be needed by base.py
        # Instantiate our inner application
        inner = self.inner(self.scope)

        return await inner(receive, send)
