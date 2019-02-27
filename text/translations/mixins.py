import logging

import re
import pymorphy2

from lxml.html import fragment_fromstring

from typing import Dict, AnyStr, List

from django.db import models
from django.utils.functional import cached_property
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from text.glosbe.api import GlosbeAPI, GlosbeThrottlingException

logger = logging.getLogger('django')


class TextWordGrammemes(models.Model):
    class Meta:
        abstract = True

    pos = models.CharField(max_length=32, null=True, blank=True)
    tense = models.CharField(max_length=32, null=True, blank=True)
    aspect = models.CharField(max_length=32, null=True, blank=True)
    form = models.CharField(max_length=32, null=True, blank=True)
    mood = models.CharField(max_length=32, null=True, blank=True)

    @classmethod
    def grammeme_add_schema(cls) -> Dict:
        grammeme_schema = {
            'type': 'object',
            'properties': {
                'pos': {'type': 'string'},
                'tense': {'type': 'string'},
                'aspect': {'type': 'string'},
                'form': {'type': 'string'},
                'mood': {'type': 'string'}
            }
        }

        return grammeme_schema

    @property
    def grammemes(self):
        return {
            'pos': self.pos,
            'tense': self.tense,
            'aspect': self.aspect,
            'form': self.form,
            'mood': self.mood
        }


class TextPhraseTranslation(models.Model):
    class Meta:
        abstract = True

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


class TextSectionDefinitionsMixin(models.Model):
    class Meta:
        abstract = True

    word_re = re.compile(r'([^\W\d]+-[^\W\d]+|[^\W\d]+)')
    morph = pymorphy2.MorphAnalyzer()
    glosbe_api = GlosbeAPI()
    body = NotImplemented

    @cached_property
    def body_text(self):
        return fragment_fromstring(self.body, create_parent='div').text_content()

    @property
    def words(self):
        for word in self.body_text.split():
            word_match = self.word_re.match(word)

            if word_match:
                yield word_match.group(0)
            else:
                continue

    def update_definitions_if_new(self, old_body: AnyStr):
        channel_layer = get_channel_layer()

        try:
            async_to_sync(channel_layer.send)('text', {'type': 'text.section.update.definitions.if.new',
                                                       'old_body': old_body, 'text_section_pk': self.pk})
        except OSError:
            pass

    def update_definitions(self):
        channel_layer = get_channel_layer()

        try:
            async_to_sync(channel_layer.send)('text', {'type': 'text.section.parse.word.definitions',
                                                       'text_section_pk': self.pk})
        except OSError:
            pass

    def parse_word_definitions(self) -> [Dict[AnyStr, List], Dict[AnyStr, int]]:
        words = {}
        word_freq = {}
        seen_translations = {}

        num_of_words = len(list(self.words))

        for i, word in enumerate(self.words):
            translations = []
            word_freq.setdefault(word, 0)
            word_freq[word] += 1

            parsed_word = self.morph.parse(word)[0]

            if word in seen_translations:
                translations = seen_translations[word]
            else:
                try:
                    translations = self.glosbe_api.translate(parsed_word.normal_form).translations
                    seen_translations[word] = translations

                    logger.info(f'Retrieved translation for word {i+1} out of {num_of_words}.')
                except GlosbeThrottlingException as e:
                    logger.error(f'GlosbeThrottlingException {e.message}')

            words.setdefault(word, [])

            word_data = dict()

            word_data['grammemes'] = {
                'pos': parsed_word.tag.POS,
                'tense': parsed_word.tag.tense,
                'aspect': parsed_word.tag.aspect,
                'form': parsed_word.tag.case,
                'mood': parsed_word.tag.mood,
            }

            word_data['translations'] = []

            if translations:
                for j in range(0, 5):
                    try:
                        translation = translations[j]

                        if translation.phrase and not translation.phrase.is_english:
                            continue

                        word_data['translations'].append(translation)
                    except IndexError:
                        break

            words[word].append(word_data)

        return words, word_freq
