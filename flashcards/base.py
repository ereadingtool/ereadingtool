from typing import Dict

from django.db import models


class Flashcard(models.Model):
    class Meta:
        abstract = True

    @property
    def phrase(self):
        raise NotImplementedError

    created_dt = models.DateTimeField(auto_now_add=True)
    next_review_dt = models.DateTimeField(null=True)

    repetitions = models.IntegerField(default=0)
    interval = models.FloatField(default=1)
    easiness = models.FloatField(default=2.5)

    def to_answer_dict(self) -> Dict:
        return self.to_dict()

    def to_dict(self) -> Dict:
        flashcard_dict = {
            'phrase': self.phrase.phrase,
            'example': self.phrase.sentence
        }

        return flashcard_dict

    def reset(self):
        concrete_fields = {field.name: field for field in Flashcard._meta.concrete_fields}

        self.repetitions = concrete_fields['repetitions'].default
        self.interval = concrete_fields['interval'].default
        self.easiness = concrete_fields['easiness'].default

        self.next_review_dt = None
