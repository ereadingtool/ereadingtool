from django.db import models

from text.definitions.models import TextWord


class Flashcards(models.Model):
    words = models.ManyToManyField(TextWord, related_name='flashcards')

    def __str__(self):
        return f"{self.student}'s flashcards ({self.words.count()} words)"