from channels.generic.websocket import AsyncJsonWebsocketConsumer

from channels.db import database_sync_to_async

from text.models import Text, TextSection
from user.student.models import Student
from question.models import Question, Answer


class Unauthorized(Exception):
    pass


@database_sync_to_async
def get_text_or_error(text_id: int, student: Student):
    if not student.user.is_authenticated:
        raise Unauthorized

    text = Text.objects.get(pk=text_id)

    return text


@database_sync_to_async
def get_text_sections_or_error(text: Text, student: Student):
    if not student.user.is_authenticated:
        raise Unauthorized

    sections = TextSection.objects.filter(text=text)

    return sections


class TextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(TextReaderConsumer, self).__init__(*args, **kwargs)

    async def start(self, text: Text, student: Student):
        pass

    async def answer(self, question: Question, answer: Answer):
        pass

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

    async def receive_json(self, content, **kwargs):
        student = self.scope['user'].user.student
