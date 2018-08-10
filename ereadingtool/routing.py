from django.conf.urls import url

from channels.security.websocket import AllowedHostsOriginValidator

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddleware

from text.consumers import TextReaderConsumer


application = ProtocolTypeRouter({
    # web socket textreader handler
    'websocket': AllowedHostsOriginValidator(AuthMiddleware(
        URLRouter([
            url(r'^text_read/(?P<text_id>\d+)/$', TextReaderConsumer),
        ])
    )),
})
