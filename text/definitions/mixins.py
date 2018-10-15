import re
import pymorphy2

from lxml.html import fragment_fromstring

from typing import Dict, AnyStr

from django.db import models
from django.utils.functional import cached_property
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from text.definitions.models import TextDefinitions
from text.glosbe.api import GlosbeAPI


class TextSectionDefinitionsMixin(models.Model):
    definitions = models.OneToOneField(TextDefinitions, null=True, related_name='text', on_delete=models.CASCADE)

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

    def parse_word_definitions(self) -> [Dict, Dict]:
        words = {}
        word_freq = {}

        for word in self.words:
            word_freq.setdefault(word, 0)
            word_freq[word] += 1

            parsed_word = self.morph.parse(word)[0]
            normalized_word = parsed_word.normal_form

            definitions = list(self.glosbe_api.translate(normalized_word).definitions.values())

            words.setdefault(normalized_word, {})

            words[normalized_word]['grammemes'] = {
                'pos': parsed_word.tag.POS,
                'tense': parsed_word.tag.tense,
                'aspect': parsed_word.tag.aspect,
                'form': parsed_word.tag.case,
                'mood': parsed_word.tag.mood,
            }

            words[normalized_word]['meanings'] = []

            if definitions:
                meanings = definitions[0].meanings

                if meanings:
                    for i in range(0, 5):
                        try:
                            meaning = meanings[i]

                            if meaning['language'] != 'en':
                                continue

                            words[normalized_word]['meanings'].append(meaning)
                        except IndexError:
                            break

        return words, word_freq
