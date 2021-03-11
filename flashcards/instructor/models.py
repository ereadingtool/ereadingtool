from typing import Dict

from django.db import models

from flashcards.base import Flashcard
from user.instructor.models import Instructor

from text.phrase.models import TextPhrase


class InstructorFlashcard(Flashcard):
    instructor = models.ForeignKey(Instructor, null=False, related_name='flashcards', on_delete=models.CASCADE)

    phrase = models.ForeignKey(TextPhrase, related_name='instructor_flashcards', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.instructor}'s flashcard for phrase {self.phrase}"

    def to_dict(self) -> Dict:
        student_flashcard_dict = super(InstructorFlashcard, self).to_dict()

        student_flashcard_dict['student'] = self.instructor.pk

        return student_flashcard_dict
