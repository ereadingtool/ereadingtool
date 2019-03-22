from typing import AnyStr
from user.models import ReaderUser

from flashcards.consumers.base import FlashcardSessionConsumer
from user.student.models import Student

from flashcards.session.base import FlashcardSession
from flashcards.student.session.models import StudentFlashcardSession

from user.mixins.models import Profile


class StudentFlashcardSessionConsumer(FlashcardSessionConsumer):
    def get_or_create_flashcard_session(self, profile: Profile) -> FlashcardSession:
        return StudentFlashcardSession.objects.get_or_create(student=profile,
                                                             current_flashcard=self.get_current_flashcard(profile))

    def get_current_flashcard(self, profile: Profile):
        return self.get_flashcards(profile)[0]

    def get_flashcards(self, profile: Profile):
        return profile.flashcards.all()

    def answer(self, user: ReaderUser, answer: AnyStr):
        super(StudentFlashcardSessionConsumer, self).answer(user, answer)

    def next(self, user: ReaderUser):
        super(StudentFlashcardSessionConsumer, self).next(user)
