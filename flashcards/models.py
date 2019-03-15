from django.db import models

from flashcards.base import Flashcards


class StudentFlashcards(Flashcards):
    def __str__(self):
        return f"{self.student}'s flashcards ({self.phrases.count()} words)"
