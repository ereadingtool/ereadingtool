import json
from typing import AnyStr
from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.generic.websocket import AsyncWebsocketConsumer
from django.utils import timezone
from jwt import InvalidTokenError

from question.models import Answer
from text.models import Text
from text_reading.exceptions import (TextReadingException, TextReadingNotAllQuestionsAnswered,
                                     TextReadingQuestionNotInSection)
from user.models import ReaderUser

from first_time_correct.models import FirstTimeCorrect

from auth.producer_auth import jwt_validation 

class Unauthorized(Exception):
    pass


@database_sync_to_async
def get_text_or_error(text_id: int, user: ReaderUser):
    if not user.id:
        raise Unauthorized

    try: 
        text = Text.objects.get(pk=text_id)
    except:
        text = None

    return text


@database_sync_to_async
def get_answer_or_error(answer_id: int, user: ReaderUser):
    if not user.id:
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

    def start_reading(self):
        raise NotImplementedError

    async def add_flashcard_phrase(self, user: ReaderUser, phrase: AnyStr, instance: int):
        try:
            if not user.id:
                raise InvalidTokenError
        except InvalidTokenError:
            await self.send_json({'error': 'Invalid JWT'})
            await self.close(code=1000)

    async def remove_flashcard_phrase(self, user: ReaderUser, phrase: AnyStr, instance: int):
        try:
            if not user.id:
                raise InvalidTokenError
        except InvalidTokenError:
            await self.send_json({'error': 'Invalid JWT'})
            await self.close(code=1000)

    @database_sync_to_async
    def get_current_text_reading_dict(self):
        return self.text_reading.to_text_reading_dict()

    async def answer(self, user: ReaderUser, answer_id: int):
        try:
            if not user.id:
                raise InvalidTokenError
        except InvalidTokenError:
            # **** if the connection is already open here, that means they've started the text 
            # with a valid JWT..? If that's the case, they've timed out :/ 
            # We must mark this as their first attempt and invalidate their JWT.
            await self.send_json({'error': 'Invalid JWT'})
            await self.close(code=1000) 


        # TODO: what to do if TextReadingException happens
        answer = await get_answer_or_error(answer_id=answer_id, user=user)

        try:
            await database_sync_to_async(self.text_reading.answer)(answer)

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': await self.get_current_text_reading_dict()
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

    async def prev(self, user: ReaderUser):
        try:
            if not user.id:
                raise InvalidTokenError
        except InvalidTokenError:
            # ****
            await self.send_json({'error': 'Invalid JWT'})
            await self.close(code=1000)

        try:
            await database_sync_to_async(self.text_reading.prev)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': await self.get_current_text_reading_dict()
            })

        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })

    async def next(self, user: ReaderUser):
        try:
            if not user.id:
                raise InvalidTokenError
        except InvalidTokenError:
            await self.send_json({'error': 'Invalid JWT'})
            await self.close(code=1000)

        try:
            await database_sync_to_async(self.text_reading.next)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': await self.get_current_text_reading_dict()
            })

        except TextReadingNotAllQuestionsAnswered as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })
        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': 'unknown', 'error_msg': 'something went wrong'}
            })

    async def connect(self):
        if not self.scope['user'].id:
            await self.accept()
            # ****
            await self.send_json({'error': 'Invalid JWT'})
            # 1002 indicates that an endpoint is terminating the connection due
            # to a protocol error. But it doesn't like that so we use 1000.
            await self.close(code=1000) 
        else:
            try:
                await self.accept()

                text_id = self.scope['url_route']['kwargs']['text_id']
                user = self.scope['user']

                self.text = await get_text_or_error(text_id=text_id, user=user)

                if not self.text:
                    raise()

                started, self.text_reading = await self.start_reading()

                if started:
                    result = await database_sync_to_async(self.text.to_text_reading_dict)()
                else:
                    result = await self.get_current_text_reading_dict()

                await database_sync_to_async(self.text_reading.set_last_read_dt)()

                await self.send_json({
                    'command': self.text_reading.current_state.name,
                    'result': result
                })
            except:
                await self.send_json({
                    "error": "Missing text"
                })

    async def receive_json(self, content, **kwargs):
        user = await jwt_validation(self.scope)

        available_cmds = {
            'next': 1,
            'prev': 1,
            'answer': 1,
            'add_flashcard_phrase': 1,
            'remove_flashcard_phrase': 1
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:

                if cmd == 'next':
                    await self.next(user=user)

                if cmd == 'prev':
                    await self.prev(user=user)

                if cmd == 'answer':
                    await self.answer(answer_id=content.get('answer_id', None), user=user)

                if cmd == 'add_flashcard_phrase':
                    await self.add_flashcard_phrase(user=user, phrase=content.get('phrase', None),
                                                    instance=content.get('instance', 0))

                if cmd == 'remove_flashcard_phrase':
                    await self.remove_flashcard_phrase(user=user, phrase=content.get('phrase', None),
                                                       instance=content.get('instance', 0))

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except TextReadingException as e:
            await self.send_json({'error': {'code': e.code, 'error_msg': e.error_msg}})


    async def disconnect(self, code):
        # check to see if they've started this text once before
        if not FirstTimeCorrect.objects.filter(student=self.student, text=self.text).exists():
            # create an entry in the first_time_correct table logging the student, their text, and their score
            try:
                ftc = FirstTimeCorrect(student=self.student, 
                                       text=self.text, 
                                       correct_answers=self.text_reading.score["section_scores"],
                                       total_answers=self.text_reading.score["possible_section_scores"],
                                       end_dt=timezone.now()
                                       )
                ftc.save()
            except BaseException as be:
                # TODO: Handle the exception accordingly, should we reply even though the connection is closed?
                pass

        return super().disconnect(code)