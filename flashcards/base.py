from typing import Dict

from django.db import models

from text.phrase.models import TextPhrase


class Flashcard(models.Model):
    class Meta:
        abstract = True

    phrase = models.ForeignKey(TextPhrase, related_name='flashcards', on_delete=models.CASCADE)

    repetitions = models.IntegerField(default=0)
    interval = models.IntegerField(default=0)
    easiness = models.IntegerField(default=0)

    def to_answer_dict(self) -> Dict:
        return self.to_dict()

    def to_dict(self) -> Dict:
        # TODO(andrew.silvernail): start gathering example sentences from the surrounding text section
        # TODO(andrew.silvernail): or else gather from Yandex
        flashcard_dict = {
            'phrase': self.phrase.phrase,
            'example': ''
        }

        return flashcard_dict
