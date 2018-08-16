from typing import AnyStr

from channels.generic.websocket import AsyncJsonWebsocketConsumer

from channels.db import database_sync_to_async

from text.models import Text, TextSection
from text_reading.models import TextReading, TextReadingException

from user.student.models import Student
from question.models import Question, Answer


class Unauthorized(Exception):
    pass


class ClientError(Exception):
    def __init__(self, code: AnyStr, error_msg: AnyStr, *args, **kargs):
        """
        Client-facing exceptions

        :param code:
        :param error_msg:
        :param args:
        :param kargs:
        """

        self.code = code
        self.error_msg = error_msg


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
        raise ClientError(code='invalid_answer', error_msg='This answer does not exist.')


@database_sync_to_async
def get_text_sections_or_error(text: Text, student: Student):
    if not student.user.is_authenticated:
        raise Unauthorized

    sections = TextSection.objects.filter(text=text)

    return sections


@database_sync_to_async
def text_reading_next_or_error(text_reading: TextReading, student: Student):
    if not student.user.is_authenticated:
        raise Unauthorized

    text_reading.next()


@database_sync_to_async
def start_text_reading_or_error(text_id: int, student: Student):
    if not student.user.is_authenticated:
        raise Unauthorized

    text_reading = None

    try:
        text = get_text_or_error(text_id=text_id, student=student)
        text_reading = TextReading.start(text=text, student=student)
    except Text.DoesNotExist as e:
        raise ClientError(code='invalid_text', error_msg='This text does not exist.')
    except Exception as e:
        raise ClientError(code='unknown_error', error_msg='Something went wrong.')

    return text_reading


class TextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(TextReaderConsumer, self).__init__(*args, **kwargs)

        self.text_reading = None

    async def current_section(self, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        if self.text_reading.current_state == self.text_reading.state_machine.in_progress:
            await self.send_json(self.text_reading.current_section.to_text_reading_dict())
        else:
            raise ClientError(code='invalid_state', error_msg="You haven't started reading yet.")

    async def start(self, text_id: int, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        text = await get_text_or_error(text_id=text_id, student=student)

        self.text_reading = TextReading.start(student=student, text=text)

        await self.send_json({
            'command': 'start',
            'result': True
        })

    async def answer(self, student: Student, answer_id: int):
        if not student.user.is_authenticated:
            raise Unauthorized

        answer = await get_answer_or_error(answer_id=answer_id, student=student)

        self.text_reading.answer(answer)

    async def next(self, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        self.text_reading.next()

        await self.send_json({
            'command': 'next',
            'result': True
        })

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

    async def receive_json(self, content, **kwargs):
        student = self.scope['user'].student

        available_cmds = {
            'next': 1,
            'start': 1,
            'answer': 1,
            'current_section': 1
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:
                if cmd == 'start':
                    await self.start(text_id=self.scope['url_route']['kwargs']['text_id'], student=student)

                if cmd == 'next':
                    await self.next(student=student)

                if cmd == 'answer':
                    await self.answer(answer_id=content.get('answer_id', None), student=student)

                if cmd == 'current_section':
                    await self.current_section(student=student)

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except TextReadingException as e:
            await self.send_json({'error': {'code': 'unknown', 'error_msg': 'An unknown error has occurred.'}})

        except ClientError as e:
            await self.send_json({'error': {'code': e.code, 'error_msg': e.error_msg}})
