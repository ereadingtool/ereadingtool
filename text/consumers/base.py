import random

from typing import AnyStr

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from question.models import Answer
from text.models import Text
from text_reading.exceptions import (TextReadingException, TextReadingNotAllQuestionsAnswered,
                                     TextReadingQuestionNotInSection)
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


class TextReaderConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(TextReaderConsumer, self).__init__(*args, **kwargs)

        self.text = None
        self.text_reading = None

    def start_reading(self):
        raise NotImplementedError

    async def add_flashcard_word(self, user: ReaderUser, word: AnyStr, instance: int):
        if not user.is_authenticated:
            raise Unauthorized

    async def remove_flashcard_word(self, user: ReaderUser, word: AnyStr, instance: int):
        if not user.is_authenticated:
            raise Unauthorized

    @database_sync_to_async
    def get_current_text_reading_dict(self, random_state):
        return self.text_reading.to_text_reading_dict(random_state=random_state)

    async def answer(self, user: ReaderUser, answer_id: int):
        if not user.is_authenticated:
            raise Unauthorized

        answer = await get_answer_or_error(answer_id=answer_id, user=user)

        try:
            await database_sync_to_async(self.text_reading.answer)(answer)

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': await self.get_current_text_reading_dict(random_state=self.scope['random_state'])
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
        if not user.is_authenticated:
            raise Unauthorized

        try:
            await database_sync_to_async(self.text_reading.prev)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': await self.get_current_text_reading_dict(random_state=self.scope['random_state'])
            })

        except TextReadingException as e:
            await self.send_json({
                'command': 'exception',
                'result': {'code': e.code, 'error_msg': e.error_msg}
            })

    async def next(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        try:
            await database_sync_to_async(self.text_reading.next)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': await self.get_current_text_reading_dict(random_state=self.scope['random_state'])
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
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            text_id = self.scope['url_route']['kwargs']['text_id']
            user = self.scope['user']

            self.scope['random_state'] = random.getstate()

            self.text = await get_text_or_error(text_id=text_id, user=user)

            started, self.text_reading = await self.start_reading()

            if started:
                result = await database_sync_to_async(self.text.to_text_reading_dict)()
            else:
                result = await self.get_current_text_reading_dict(random_state=self.scope['random_state'])

            await database_sync_to_async(self.text_reading.set_last_read_dt)()

            await self.send_json({
                'command': self.text_reading.current_state.name,
                'result': result
            })

    async def receive_json(self, content, **kwargs):
        user = self.scope['user']

        available_cmds = {
            'next': 1,
            'prev': 1,
            'answer': 1,
            'add_flashcard_word': 1,
            'remove_flashcard_word': 1
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

                if cmd == 'add_flashcard_word':
                    await self.add_flashcard_word(user=user, word=content.get('word', None),
                                                  instance=content.get('instance', 0))

                if cmd == 'remove_flashcard_word':
                    await self.remove_flashcard_word(user=user, word=content.get('word', None),
                                                     instance=content.get('instance', 0))

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except TextReadingException as e:
            await self.send_json({'error': {'code': e.code, 'error_msg': e.error_msg}})
