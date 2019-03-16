from typing import AnyStr
from user.models import ReaderUser

from flashcards.consumers.base import FlashcardSessionConsumer


class StudentFlashcardSessionConsumer(FlashcardSessionConsumer):
    def answer(self, user: ReaderUser, answer: AnyStr):
        super(StudentFlashcardSessionConsumer, self).answer(user, answer)

    def next(self, user: ReaderUser):
        super(StudentFlashcardSessionConsumer, self).next(user)

    def flip(self, user: ReaderUser):
        super(StudentFlashcardSessionConsumer, self).flip(user)
