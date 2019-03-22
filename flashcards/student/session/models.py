from typing import List

from django.db import models

from flashcards.student.models import StudentFlashcard
from flashcards.session.base import FlashcardSession
from user.student.models import Student


class StudentFlashcardSession(FlashcardSession):
    student = models.OneToOneField(Student, null=False, related_name='flashcard_session', on_delete=models.CASCADE)

    current_flashcard = models.OneToOneField(StudentFlashcard, null=True, blank=True, related_name='session',
                                             on_delete=models.DO_NOTHING)

    def __init__(self, *args, **kwargs):
        super(StudentFlashcardSession, self).__init__(*args, **kwargs)

        if not self.current_flashcard:
            try:
                self.current_flashcard = self.student.flashcards.filter()[0]
            except IndexError:
                pass

    def flashcards(self) -> List[StudentFlashcard]:
        return self.student.flashcards.all()
