from typing import List

from django.db import models

from flashcards.student.models import StudentFlashcard
from flashcards.session.base import FlashcardSession
from user.student.models import Student


class StudentFlashcardSession(FlashcardSession):
    student = models.ForeignKey(Student, null=False, related_name='flashcard_sessions', on_delete=models.CASCADE)

    current_flashcard = models.ForeignKey(StudentFlashcard, null=True, blank=True, related_name='flashcard_sessions',
                                          on_delete=models.DO_NOTHING)

    @property
    def flashcards(self) -> List[StudentFlashcard]:
        return self.student.flashcards.filter()
