from typing import Dict, AnyStr, Optional

from django.db import models

from django.urls import reverse

from text.models import TextSection
from text.translations.mixins import TextPhraseGrammemes


class TextPhrase(TextPhraseGrammemes, models.Model):
    class Meta:
        unique_together = (('instance', 'phrase', 'text_section'),)

    text_section = models.ForeignKey(TextSection, related_name='translated_words', on_delete=models.CASCADE)
    instance = models.IntegerField(default=0)

    phrase = models.CharField(max_length=128, blank=False)

    def __str__(self):
        return f'{self.phrase} instance {self.instance+1} from text section {self.text_section}'

    def to_dict(self):
        translation = None

        try:
            translation = self.translations.filter(correct_for_context=True)[0]
        except IndexError:
            pass

        text_word_dict = {
            'phrase': self.phrase,
            'grammemes': self.grammemes,
            'translation': translation.phrase if translation else None,
        }

        return text_word_dict

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

    def to_translations_dict(self):
        translation_dict = {
            'id': self.pk,
            # phrase.instance is the phrase instance within a particular section
            'instance': self.instance,
            'phrase': self.phrase,
            'grammemes': self.grammemes,
            'translations': [translation.to_dict() for translation in
                             self.translations.all()] or None,
            'group': None,
            'word_type': 'word_type',
            'endpoints': {
                'text_word': reverse('text-word-api', kwargs={'pk': self.pk}),
                'translations': reverse('text-word-translation-api', kwargs={'pk': self.pk})
            }
        }

        return translation_dict


class TextPhraseTranslation(models.Model):
    text_phrase = models.ForeignKey(TextPhrase, related_name='translations', on_delete=models.CASCADE)

    phrase = models.TextField()
    correct_for_context = models.BooleanField(default=False)

    @classmethod
    def to_set_json_schema(cls) -> Dict:
        schema = {
            'type': 'array',
            'items': {
                'type': 'object',
                'properties': {
                    'id': {'type': 'number'},
                    'correct_for_context': {'type': 'boolean'},
                    'text': {'type': 'string'},
                }
            },
            'minItems': 1
        }

        return schema

    @classmethod
    def to_add_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'phrase': {'type': 'string'},
            }
        }

        return schema

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

    @classmethod
    def to_word_json_schema(cls):
        return {
            'id': {'type': 'number'},
            'word_type': {'type': 'string', 'enum': ['single', 'compound']}
        }

    @classmethod
    def to_merge_json_schema(cls):
        return {
            'type': 'object',
            'properties': {
                'translations': {
                    'type': 'array',
                    'items': {
                        'type': 'object',
                        'properties': {
                            'correct_for_context': {'type': 'boolean'},
                            'phrase': {'type': 'string'},
                        }
                    },
                    'minItems': 1
                },
                'words': {
                    'type': 'array',
                    'items': {
                        'type': 'object',
                        'properties': cls.to_word_json_schema()
                    },
                    'minItems': 1
                }
            }
        }

    def __str__(self):
        return f'{self.text_phrase.phrase} - {self.phrase}'

    def to_dict(self):
        return {
            'id': self.pk,
            'endpoint': reverse('text-word-translation-api', kwargs={
                'pk': self.phrase.pk,
                'tr_pk': self.pk,
                'word_type': 'word_type'
            }),
            'correct_for_context': self.correct_for_context,
            'text': self.phrase
        }

    @classmethod
    def create(cls, text_phrase: TextPhrase, phrase: AnyStr, correct_for_context: Optional[bool] = False):
        text_translation = cls.objects.create(text_phrase=text_phrase,
                                              phrase=phrase,
                                              correct_for_context=correct_for_context)

        return text_translation
