from typing import AnyStr

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from flashcards.models import Flashcard
from flashcards.consumers.exceptions import FlashcardSessionException
from user.models import ReaderUser

from user.mixins.models import Profile


class Unauthorized(Exception):
    pass


class FlashcardSessionConsumer(AsyncJsonWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super(FlashcardSessionConsumer, self).__init__(*args, **kwargs)

        self.flashcard_session = None

    def get_or_create_flashcard_session(self, profile: Profile):
        raise NotImplementedError

    async def choose_mode(self, mode: AnyStr, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        self.flashcard_session.set_mode(mode)

        await database_sync_to_async(self.flashcard_session.save)()

        await self.send_serialized_session_command()

    @database_sync_to_async
    def start(self, user: ReaderUser):
        return self.get_or_create_flashcard_session(profile=user.profile)

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

    async def send_serialized_session_command(self):
        await self.send_json({
            'command': self.flashcard_session.state_name,
            'result': self.flashcard_session.serialize()
        })

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            user = self.scope['user']

            self.flashcard_session, started = await self.start(user)

            await self.send_serialized_session_command()

    async def receive_json(self, content, **kwargs):
        user = self.scope['user']

        available_cmds = {
            'choose_mode': 1,
            'flip': 1,
            'next': 1,
            'answer': 1,
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:
                if cmd == 'choose_mode':
                    await self.choose_mode(mode=content.get('mode', None), user=user)

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
