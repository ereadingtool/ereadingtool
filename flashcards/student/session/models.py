from typing import List

from django.db import models

from flashcards.student.models import StudentFlashcard
from flashcards.session.base import FlashcardSession
from user.student.models import Student


def SET_NULL_OR_CASCADE(collector, field, sub_objs, using):
    if sub_objs[0].flashcards.count() > 1:
        models.SET_NULL(collector, field, sub_objs, using)
    else:
        models.CASCADE(collector, field, sub_objs, using)


class StudentFlashcardSession(FlashcardSession):
    student = models.OneToOneField(Student, null=False, related_name='flashcard_session', on_delete=models.CASCADE)

    current_flashcard = models.OneToOneField(StudentFlashcard, null=True, blank=True, related_name='session',
                                             on_delete=SET_NULL_OR_CASCADE)

    @property
    def flashcards(self) -> List[StudentFlashcard]:
        return self.student.flashcards.filter()
