from typing import List

from django.db import models
from flashcards.base import Flashcard


class FlashcardSession(models.Model):
    class Meta:
        abstract = True

    """
    A model that keeps track of individual flashcard sessions.
    """

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True)

    @property
    def flashcards(self) -> List[Flashcard]:
        raise NotImplementedError

    def next_flashcard(self) -> Flashcard:
        return self.flashcards[0]
