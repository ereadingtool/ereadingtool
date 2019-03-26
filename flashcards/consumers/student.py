from typing import AnyStr
from user.models import ReaderUser

from flashcards.consumers.base import FlashcardSessionConsumer
from user.student.models import Student

from flashcards.session.base import FlashcardSession
from flashcards.student.session.models import StudentFlashcardSession

from user.mixins.models import Profile


class StudentFlashcardSessionConsumer(FlashcardSessionConsumer):
    def get_or_create_flashcard_session(self, profile: Profile) -> FlashcardSession:
        return StudentFlashcardSession.objects.get_or_create(student=profile)
