from typing import AnyStr

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from flashcards.models import Flashcard
from flashcards.consumers.exceptions import FlashcardSessionException
from user.models import ReaderUser


class Unauthorized(Exception):
    pass


class FlashcardSessionConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(FlashcardSessionConsumer, self).__init__(*args, **kwargs)

        self.flashcard_session = None

    @database_sync_to_async
    def start(self, user: ReaderUser):
        self.flashcard_session, started = self.get_or_create_flashcard_session(user=user)

        self.send_json(self.flashcard_session.to_dict())

    @database_sync_to_async
    def get_or_create_flashcard_session(self, user: ReaderUser):
        profile = user.profile

        return profile.get_or_create_flashcard_session()

    def flip_card(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        self.send_json(self.flashcard_session.flip_card().to_dict())

    @database_sync_to_async
    def answer(self, user: ReaderUser, answer: AnyStr):
        if not user.is_authenticated:
            raise Unauthorized

        self.send_json(self.flashcard_session.answer(answer).to_dict())

    async def next(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        await self.send_json(self.flashcard_session.next().to_dict())

    async def flip(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        self.flip_card(self.flashcard_session.flip().to_dict())

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            user = self.scope['user']

            await self.start(user)

    async def receive_json(self, content, **kwargs):
        user = self.scope['user']

        available_cmds = {
            'flip': 1,
            'next': 1,
            'answer': 1,
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:
                if cmd == 'flip':
                    await self.flip(user=user)

                if cmd == 'next':
                    await self.next(user=user)

                if cmd == 'answer':
                    await self.answer(answer=content.get('answer', None), user=user)

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except FlashcardSessionException as e:
            await self.send_json({'error': {'code': e.code, 'error_msg': e.error_msg}})
