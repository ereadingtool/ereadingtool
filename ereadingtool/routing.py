from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.conf.urls import url

from text.consumers import TextReaderConsumer

application = ProtocolTypeRouter({
    # web socket textreader handler
    'websocket': AllowedHostsOriginValidator(AuthMiddlewareStack(
        URLRouter([
            url(r'^text_read/(?P<text_id>\d+)/$', TextReaderConsumer),
        ])
    )),
})
