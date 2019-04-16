import re

from typing import Dict, AnyStr, Optional, Union

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

    @property
    def sentence(self) -> Union[AnyStr, None]:
        matches = re.match(r'(?P<sentence>(.+)' + self.phrase + '(.+?)\\.)',
                           self.text_section.body_text,
                           re.DOTALL | re.MULTILINE)

        try:
            return matches[self.instance]
        except (TypeError, IndexError):
            return None

    @property
    def child_instance(self):
        try:
            return self.textword
        except models.ObjectDoesNotExist:
            return self.textwordgroup

    def __str__(self):
        return f'{self.phrase} instance {self.instance+1} from text section {self.text_section}'

    @property
    def serialized_grammemes(self):
        return [item for item in self.grammemes.items()]

    def to_dict(self):
        translation = None

        try:
            translation = self.translations.filter(correct_for_context=True)[0]
        except IndexError:
            pass

        text_word_dict = {
            'phrase': self.phrase,
            'grammemes': self.serialized_grammemes,
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
                'phrase': {'type': 'string'},
                'grammeme': cls.grammeme_add_schema()
            },
            'minItems': 1,
            'required': ['text_section', 'instance', 'phrase']
        }

        return schema

    @classmethod
    def to_update_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'grammemes': cls.grammeme_add_schema()
            },
            'minItems': 1,
            'required': ['grammemes']
        }

        return schema

    @property
    def word_type(self):
        try:
            if self.textwordgroup:
                return 'compound'

        except (AttributeError, models.ObjectDoesNotExist):
            return 'single'

    def to_translations_dict(self):
        translation_dict = {
            'id': self.pk,
            # phrase.instance is the phrase instance within a particular section
            'instance': self.instance,
            'phrase': self.phrase,
            'grammemes': self.serialized_grammemes,
            'translations': [translation.to_dict() for translation in
                             self.translations.all()] or None,
            'group': None,
            'word_type': self.word_type,
            'endpoints': {
                'text_word': reverse('text-word-api', kwargs={'pk': self.pk}),
                'translations': reverse('text-word-translation-api', kwargs={'pk': self.pk})
            }
        }

        return translation_dict

    def to_text_reading_dict(self) -> Dict:
        text_phrase_reading_dict = self.child_instance.to_translations_dict()

        # students dont need to know about endpoints
        if 'endpoints' in text_phrase_reading_dict:
            del text_phrase_reading_dict['endpoints']

        return text_phrase_reading_dict


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
            },
            'required': ['correct_for_context']
        }

        return schema

    @classmethod
    def to_word_json_schema(cls):
        return {
            'id': {'type': 'number'},
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
                'pk': self.text_phrase.pk,
                'tr_pk': self.pk,
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
