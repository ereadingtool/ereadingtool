from typing import Dict

from django.db import models

from text.phrase.models import TextPhrase


class Flashcard(models.Model):
    class Meta:
        abstract = True

    created_dt = models.DateTimeField(auto_now_add=True)

    phrase = models.ForeignKey(TextPhrase, related_name='flashcards', on_delete=models.CASCADE)

    repetitions = models.IntegerField(default=0)
    interval = models.IntegerField(default=0)
    easiness = models.IntegerField(default=0)

    def to_answer_dict(self) -> Dict:
        return self.to_dict()

    def to_dict(self) -> Dict:
        flashcard_dict = {
            'phrase': self.phrase.phrase,
            'example': self.phrase.sentence
        }

        return flashcard_dict
