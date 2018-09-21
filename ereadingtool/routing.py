from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.conf.urls import url

from text.consumers.student import StudentTextReaderConsumer
from text.consumers.instructor import InstructorTextReaderConsumer

application = ProtocolTypeRouter({
    # web socket textreader handler
    'websocket': AllowedHostsOriginValidator(AuthMiddlewareStack(
        URLRouter([
            url(r'^student/text_read/(?P<text_id>\d+)/$', StudentTextReaderConsumer),
            url(r'^instructor/text_read/(?P<text_id>\d+)/$', InstructorTextReaderConsumer),
        ])
    )),
})
