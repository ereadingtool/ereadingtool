from django.db import models

from flashcards.session.base import FlashcardSession
from user.student.models import Student


class StudentFlashcardSession(FlashcardSession):
    student = models.ForeignKey(Student, null=False, related_name='flashcard_sessions', on_delete=models.CASCADE)
