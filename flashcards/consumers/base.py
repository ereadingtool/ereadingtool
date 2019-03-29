from typing import AnyStr, List

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

    def get_flashcards(self, profile: Profile) -> List[Flashcard]:
        return profile.flashcards.filter()

    async def rate_quality(self, user: ReaderUser, rating: int):
        if not user.is_authenticated:
            raise Unauthorized

        await database_sync_to_async(self.flashcard_session.rate_quality)(rating)

        await self.send_serialized_session_command()

    async def review_answer(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        await database_sync_to_async(self.flashcard_session.review)()

        await self.send_serialized_session_command()

    async def choose_mode(self, mode: AnyStr, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        self.flashcard_session.set_mode(mode)

        await database_sync_to_async(self.flashcard_session.save)()

        await self.send_serialized_session_command()

    async def answer(self, user: ReaderUser, answer: AnyStr):
        if not user.is_authenticated:
            raise Unauthorized

        await database_sync_to_async(self.flashcard_session.answer)(answer)

        await self.send_serialized_session_command()

    async def next(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        await database_sync_to_async(self.flashcard_session.next)()

        await self.send_serialized_session_command()

    async def send_serialized_session_command(self):
        await self.send_json({
            'command': self.flashcard_session.state_name,
            'mode': self.flashcard_session.mode,
            'result': self.flashcard_session.serialize()
        })

    async def start(self, user: ReaderUser):
        if not user.is_authenticated:
            raise Unauthorized

        self.flashcard_session.start()

        await database_sync_to_async(self.flashcard_session.save)()

        await self.send_serialized_session_command()

    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

            user = self.scope['user']

            flashcards = await database_sync_to_async(self.get_flashcards)(user.profile)

            if not flashcards:
                # init state
                # could be useful for other things, but for now we just use it to communicate that the user has no
                # flashcards
                await self.send_json({
                    'command': 'init',
                    'mode': None,
                    'result': {
                        'flashcards': []
                    }
                })
            else:
                self.flashcard_session, started = await database_sync_to_async(self.get_or_create_flashcard_session)(
                    profile=user.profile)

                await self.send_serialized_session_command()

    async def receive_json(self, content, **kwargs):
        user = self.scope['user']

        available_cmds = {
            'start': 1,
            'choose_mode': 1,
            'next': 1,
            'answer': 1,
            'review_answer': 1,
            'rate_quality': 1
        }

        try:
            cmd = content.get('command', None)

            if cmd in available_cmds:
                if cmd == 'start':
                    await self.start(user=user)

                if cmd == 'choose_mode':
                    await self.choose_mode(mode=content.get('mode', None), user=user)

                if cmd == 'next':
                    await self.next(user=user)

                if cmd == 'answer':
                    await self.answer(answer=content.get('answer', None), user=user)

                if cmd == 'review_answer':
                    await self.review_answer(user=user)

                if cmd == 'rate_quality':
                    await self.rate_quality(user=user, rating=content.get('rating', None))

            else:
                await self.send_json({'error': f'{cmd} is not a valid command.'})

        except FlashcardSessionException as e:
            await self.send_json({'mode': self.flashcard_session.mode,
                                  'command': 'exception', 'result': {'code': e.code, 'error_msg': e.error_msg}})
