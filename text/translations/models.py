from typing import Dict

from django.db import models

from text.models import TextSection


class TextWord(models.Model):
    class Meta:
        unique_together = (('instance', 'word', 'text_section'),)

    text_section = models.ForeignKey(TextSection, related_name='translated_words', on_delete=models.CASCADE)

    instance = models.IntegerField(default=0)
    word = models.CharField(max_length=128, blank=False)

    pos = models.CharField(max_length=32, null=True, blank=True)
    tense = models.CharField(max_length=32, null=True, blank=True)
    aspect = models.CharField(max_length=32, null=True, blank=True)
    form = models.CharField(max_length=32, null=True, blank=True)
    mood = models.CharField(max_length=32, null=True, blank=True)

    @property
    def grammemes(self):
        return {
            'pos': self.pos,
            'tense': self.tense,
            'aspect': self.aspect,
            'form': self.form,
            'mood': self.mood
        }

    def __str__(self):
        return f'{self.word} ({self.pos, self.tense, self.aspect, self.form, self.mood})'

    def to_dict(self):
        translation = None

        try:
            translation = self.translations.filter(correct_for_context=True)[0]
        except IndexError:
            pass

        return {
            'word': self.word,
            'grammemes': self.grammemes,
            'translation': translation.phrase if translation else None
        }


class TextWordTranslation(models.Model):
    word = models.ForeignKey(TextWord, related_name='translations', on_delete=models.CASCADE)
    correct_for_context = models.BooleanField(default=False)

    phrase = models.TextField()

    def __str__(self):
        return f'{self.word} - {self.phrase}'

    def to_dict(self):
        return {
            'id': self.pk,
            'correct_for_context': self.correct_for_context,
            'text': self.phrase
        }

    @classmethod
    def to_update_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'correct_for_context': {'type': 'boolean'},
                'text': {'type': 'string'},
            }
        }

        return schema