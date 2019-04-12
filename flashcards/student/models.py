from typing import Dict

from django.db import models

from flashcards.base import Flashcard
from user.student.models import Student
from text.phrase.models import TextPhrase


class StudentFlashcard(Flashcard):
    student = models.ForeignKey(Student, null=False, related_name='flashcards', on_delete=models.CASCADE)

    phrase = models.ForeignKey(TextPhrase, related_name='student_flashcards', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.student}'s flashcard for phrase {self.phrase}"

    def to_dict(self) -> Dict:
        student_flashcard_dict = super(StudentFlashcard, self).to_dict()

        student_flashcard_dict['student'] = self.student.pk

        return student_flashcard_dict
