from typing import Dict, AnyStr, Optional

from django.db import models

from django.urls import reverse

from text.models import TextSection
from text.translations.mixins import TextWordGrammemes, TextPhraseTranslation


class TextWord(TextWordGrammemes, models.Model):
    class Meta:
        unique_together = (('instance', 'word', 'text_section'),)

    text_section = models.ForeignKey(TextSection, related_name='translated_words', on_delete=models.CASCADE)

    instance = models.IntegerField(default=0)
    word = models.CharField(max_length=128, blank=False)

    word_type = 'single'

    def __str__(self):
        return f'{self.word} instance {self.instance+1}'

    def to_dict(self):
        translation = None

        text_word_dict = {
            'word': self.word,
            'grammemes': self.grammemes,
            'translation': translation.phrase if translation else None,
        }

        try:
            translation = self.translations.filter(correct_for_context=True)[0]
        except IndexError:
            pass

        try:
            text_word_dict['group'] = {
                'group': self.group_word.group_id,
                'order': self.group_word.order
            }
        except models.ObjectDoesNotExist:
            text_word_dict['group'] = None

        return text_word_dict

    def to_translations_dict(self):
        translation_dict = {
            'id': self.pk,
            # word.instance is the word instance within a particular section
            'instance': self.instance,
            'word': self.word,
            'grammemes': self.grammemes,
            'translations': [translation.to_dict() for translation in
                             self.translations.all()] or None,
            'group': None,
            'word_type': self.word_type,
            'endpoints': {
                'text_word': reverse('text-word-api', kwargs={'pk': self.pk}),
                'translations': reverse('text-word-translation-api', kwargs={'pk': self.pk})
            }
        }

        try:
            translation_dict['group'] = {
                'id': self.group_word.group.pk,
                'instance': self.group_word.group.instance,
                'pos': self.group_word.order,
                'length': self.group_word.group.components.count()
            }
        except models.ObjectDoesNotExist:
            pass

        return translation_dict

    @classmethod
    def create(cls, **params) -> 'TextWord':
        params['text_section'] = TextSection.objects.get(pk=params['text_section'])

        return TextWord.objects.create(**params)

    @classmethod
    def to_add_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'text_section': {'type': 'number'},
                'instance': {'type': 'number'},
                'word': {'type': 'string'},
                'grammeme': cls.grammeme_add_schema()
            },
            'minItems': 1,
            'required': ['text_section', 'instance', 'word']
        }

        return schema

    @classmethod
    def to_update_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'word_type': {'type': 'string'},
                'grammemes': cls.grammeme_add_schema()
            },
            'minItems': 1,
            'required': ['word_type', 'grammemes']
        }

        return schema


class TextWordTranslation(TextPhraseTranslation, models.Model):
    word = models.ForeignKey(TextWord, related_name='translations', on_delete=models.CASCADE)

    def __str__(self):
        return f'{self.word} - {self.phrase}'

    def to_dict(self):
        return {
            'id': self.pk,
            'endpoint': reverse('text-word-translation-api', kwargs={
                'pk': self.word.pk,
                'tr_pk': self.pk,
                'word_type': self.word.word_type
            }),
            'correct_for_context': self.correct_for_context,
            'text': self.phrase
        }

    @classmethod
    def create(cls, word: TextWord, phrase: AnyStr, correct_for_context: Optional[bool] = False):
        text_word_translation = cls.objects.create(word=word, phrase=phrase, correct_for_context=correct_for_context)

        return text_word_translation
