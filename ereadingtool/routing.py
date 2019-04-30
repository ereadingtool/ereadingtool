from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter, ChannelNameRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.conf.urls import url

from flashcards.consumers.student import StudentFlashcardSessionConsumer

from text.consumers.student import StudentTextReaderConsumer
from text.consumers.instructor import InstructorTextReaderConsumer, ParseTextSectionForDefinitions


application = ProtocolTypeRouter({
    # web socket textreader handler
    'websocket': AllowedHostsOriginValidator(AuthMiddlewareStack(
        URLRouter([
            # text reading
            url(r'^student/text_read/(?P<text_id>\d+)/$', StudentTextReaderConsumer),
            url(r'^instructor/text_read/(?P<text_id>\d+)/$', InstructorTextReaderConsumer),

            # flashcards
            url(r'^student/flashcards/$', StudentFlashcardSessionConsumer),
            # url(r'^instructor/flashcard/$', InstructorFlashcardSessionConsumer),
        ])
    )),
    'channel': ChannelNameRouter({
        'text': ParseTextSectionForDefinitions
    })
})
