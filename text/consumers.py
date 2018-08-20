from typing import AnyStr

from channels.generic.websocket import AsyncJsonWebsocketConsumer

from channels.db import database_sync_to_async

from text.models import Text, TextSection
from text_reading.models import TextReading, TextReadingException

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
def get_answer_or_error(answer_id: int, student: Student):
    if not student.user.is_authenticated:
        raise Unauthorized

    try:
        return Answer.objects.get(pk=answer_id)
    except Answer.DoesNotExist:
        raise TextReadingException(code='invalid_answer', error_msg='This answer does not exist.')


class TextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(TextReaderConsumer, self).__init__(*args, **kwargs)

        self.text = None
        self.text_reading = None

    async def answer(self, student: Student, answer_id: int):
        if not student.user.is_authenticated:
            raise Unauthorized

        answer = await get_answer_or_error(answer_id=answer_id, student=student)

        self.text_reading.answer(answer)

    async def prev(self, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        self.text_reading.prev()

        if self.text_reading.current_state == self.text_reading.state_machine.in_progress:
            await self.send_json({
                'command': 'prev',
                'result': self.text_reading.get_current_section().to_text_reading_dict()
            })

        elif self.text_reading.current_state == self.text_reading.state_machine.intro:
            await self.send_json({
                'command': 'start',
                'result': self.text.to_text_reading_dict()
            })

    async def next(self, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        self.text_reading.next()

        if self.text_reading.current_state == self.text_reading.state_machine.in_progress:
            await self.send_json({
                'command': 'next',
                'result': self.text_reading.get_current_section().to_text_reading_dict()
            })

        elif self.text_reading.current_state == self.text_reading.state_machine.complete:
            await self.send_json({
                'command': 'complete',
                # scores
                'result': {}
            })

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            text_id = self.scope['url_route']['kwargs']['text_id']
            student = self.scope['user'].student

            self.text = await get_text_or_error(text_id=text_id, student=student)

            self.text_reading = TextReading.start(student=student, text=self.text)

            await self.send_json({
                'command': 'start',
                'result': self.text.to_text_reading_dict()
            })

    async def receive_json(self, content, **kwargs):
        student = self.scope['user'].student

        available_cmds = {
            'next': 1,
            'prev': 1,
            'answer': 1,
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:

                if cmd == 'next':
                    await self.next(student=student)

                if cmd == 'prev':
                    await self.prev(student=student)

                if cmd == 'answer':
                    await self.answer(answer_id=content.get('answer_id', None), student=student)

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except TextReadingException as e:
            await self.send_json({'error': {'code': e.code, 'error_msg': e.error_msg}})
