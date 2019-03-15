from django.db import models

from text.phrase.models import TextPhrase


class Flashcards(models.Model):
    class Meta:
        abstract = True

    phrases = models.ManyToManyField(TextPhrase, related_name='flashcards')

    def to_dict(self):
        return [(text_phrase.phrase, text_phrase.child_instance.to_text_reading_dict())
                for text_phrase in self.phrases.all()]
