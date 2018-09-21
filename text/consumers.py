from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from question.models import Answer
from text.models import Text
from text_reading.models import (InstructorTextReading, StudentTextReading)
from text_reading.exceptions import (TextReadingException, TextReadingNotAllQuestionsAnswered,
                                     TextReadingQuestionNotInSection)

from user.student.models import Student
from user.instructor.models import Instructor

from user.models import ReaderUser


class Unauthorized(Exception):
    pass


@database_sync_to_async
def get_text_or_error(text_id: int, user: ReaderUser):
    if not user.is_authenticated:
        raise Unauthorized

    text = Text.objects.get(pk=text_id)

    return text


@database_sync_to_async
def get_answer_or_error(answer_id: int, user: ReaderUser):
    if not user.is_authenticated:
        raise Unauthorized

    try:
        return Answer.objects.get(pk=answer_id)
    except Answer.DoesNotExist:
        raise TextReadingException(code='invalid_answer', error_msg='This answer does not exist.')


class InstructorTextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(InstructorTextReaderConsumer, self).__init__(*args, **kwargs)

        self.text = None
        self.text_reading = None

    async def answer(self, instructor: Instructor, answer_id: int):
        if not instructor.user.is_authenticated:
            raise Unauthorized

        answer = await get_answer_or_error(answer_id=answer_id, user=instructor.user)

        try:
            await database_sync_to_async(self.text_reading.answer)(answer)

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': self.text_reading.to_text_reading_dict()
            })

        except TextReadingQuestionNotInSection:
            await self.send_json({
                'command': 'exception',
                'result': {'code': 'unknown', 'error_msg': 'Something went wrong.'}
            })

        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })

    async def prev(self, instructor: Instructor):
        if not instructor.user.is_authenticated:
            raise Unauthorized

        try:
            await database_sync_to_async(self.text_reading.prev)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': self.text_reading.to_text_reading_dict()
            })

        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })

    async def next(self, instructor: Instructor):
        if not instructor.user.is_authenticated:
            raise Unauthorized

        try:
            await database_sync_to_async(self.text_reading.next)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': self.text_reading.to_text_reading_dict()
            })

        except TextReadingNotAllQuestionsAnswered as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })
        except TextReadingException:
            await self.send_json({
                'command': 'exception',
                'result': {'code': 'unknown', 'error_msg': 'something went wrong'}
            })

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            text_id = self.scope['url_route']['kwargs']['text_id']
            instructor = self.scope['user'].instructor

            self.text = await get_text_or_error(text_id=text_id, user=instructor.user)

            started, self.text_reading = await database_sync_to_async(InstructorTextReading.start_or_resume)(
                instructor=instructor, text=self.text)

            if started:
                await self.send_json({
                    'command': self.text_reading.current_state.name,
                    'result': self.text.to_text_reading_dict()
                })
            else:
                await self.send_json({
                    'command': self.text_reading.current_state.name,
                    'result': self.text_reading.to_text_reading_dict()
                })

    async def receive_json(self, content, **kwargs):
        instructor = self.scope['user'].instructor

        available_cmds = {
            'next': 1,
            'prev': 1,
            'answer': 1,
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:

                if cmd == 'next':
                    await self.next(instructor=instructor)

                if cmd == 'prev':
                    await self.prev(instructor=instructor)

                if cmd == 'answer':
                    await self.answer(answer_id=content.get('answer_id', None), instructor=instructor)

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except TextReadingException as e:
            await self.send_json({'error': {'code': e.code, 'error_msg': e.error_msg}})


class StudentTextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(StudentTextReaderConsumer, self).__init__(*args, **kwargs)

        self.text = None
        self.text_reading = None

    async def answer(self, student: Student, answer_id: int):
        if not student.user.is_authenticated:
            raise Unauthorized

        answer = await get_answer_or_error(answer_id=answer_id, user=student.user)

        try:
            await database_sync_to_async(self.text_reading.answer)(answer)

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': self.text_reading.to_text_reading_dict()
            })

        except TextReadingQuestionNotInSection:
            await self.send_json({
                'command': 'exception',
                'result': {'code': 'unknown', 'error_msg': 'Something went wrong.'}
            })

        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })

    async def prev(self, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        try:
            await database_sync_to_async(self.text_reading.prev)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': self.text_reading.to_text_reading_dict()
            })

        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })

    async def next(self, student: Student):
        if not student.user.is_authenticated:
            raise Unauthorized

        try:
            await database_sync_to_async(self.text_reading.next)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': self.text_reading.to_text_reading_dict()
            })

        except TextReadingNotAllQuestionsAnswered as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })
        except TextReadingException:
            await self.send_json({
                'command': 'exception',
                'result': {'code': 'unknown', 'error_msg': 'something went wrong'}
            })

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            text_id = self.scope['url_route']['kwargs']['text_id']
            student = self.scope['user'].student

            self.text = await get_text_or_error(text_id=text_id, user=student.user)

            started, self.text_reading = await database_sync_to_async(StudentTextReading.start_or_resume)(
                student=student, text=self.text)

            if started:
                await self.send_json({
                    'command': self.text_reading.current_state.name,
                    'result': self.text.to_text_reading_dict()
                })
            else:
                await self.send_json({
                    'command': self.text_reading.current_state.name,
                    'result': self.text_reading.to_text_reading_dict()
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


class TextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(TextReaderConsumer, self).__init__(*args, **kwargs)

        self.args = args
        self.kwargs = kwargs

        self.consumer = None

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            profile = self.scope['user'].profile

            if not self.consumer:
                if isinstance(profile, Student):
                    self.consumer = StudentTextReaderConsumer(*self.args, **self.kwargs)
                elif isinstance(profile, Instructor):
                    self.consumer = InstructorTextReaderConsumer(*self.args, **self.kwargs)

                self.consumer.base_send = self.base_send

            await self.consumer.connect()

    async def receive_json(self, content, **kwargs):
        if not self.consumer:
            await self.send_json({'error': {'code': 'no_consumer', 'error_msg': 'Not a valid user.'}})

        await self.consumer.receive_json(content, **kwargs)
