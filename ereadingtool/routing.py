from django.conf.urls import url

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import SessionMiddleware, CookieMiddleware

from text.consumers import TextReaderConsumer


application = ProtocolTypeRouter({
    # web socket text questions handler
    'websocket': CookieMiddleware(SessionMiddleware(
        URLRouter([
            url(r'^text_reader/$', TextReaderConsumer),
        ])
    )),
})
