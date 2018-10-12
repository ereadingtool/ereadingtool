import re
import pymorphy2

from typing import Dict

from bs4 import BeautifulSoup
from django.db import models
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from text.definitions.models import TextDefinitions
from text.glosbe.api import GlosbeAPI


class TextSectionDefinitionsMixin(models.Model):
    definitions = models.OneToOneField(TextDefinitions, null=True, related_name='text', on_delete=models.CASCADE)

    class Meta:
        abstract = True

    word_re = re.compile(r'(\w+-\w+|\w+)')
    morph = pymorphy2.MorphAnalyzer()
    glosbe_api = GlosbeAPI()
    body = NotImplemented

    def update_definitions(self):
        channel_layer = get_channel_layer()

        async_to_sync(channel_layer.send)('text', {'type': 'text.parse.word.definitions',
                                                   'text_section_pk': self.pk})

    def parse_for_definitions(self) -> [Dict, Dict]:
        words = {}
        word_freq = {}

        text = BeautifulSoup(self.body, features='html.parser').get_text()

        for word in text.split():
            word_match = self.word_re.match(word)

            if word_match:
                word = word_match.group(0)

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
