from django.db import models

from text.phrase.models import TextPhrase


class Flashcards(models.Model):
    words = models.ManyToManyField(TextPhrase, related_name='flashcards')

    def __str__(self):
        return f"{self.student}'s flashcards ({self.words.count()} words)"

    def to_dict(self):
        return [(text_phrase.phrase, text_phrase.child_instance.to_text_reading_dict())
                for text_phrase in self.words.all()]
