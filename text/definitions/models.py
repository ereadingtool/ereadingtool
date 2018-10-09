import re
from bs4 import BeautifulSoup

from typing import Dict

import pymorphy2
from django.db import models
from django.utils.functional import cached_property

from text.glosbe.api import GlosbeAPI


class TextDefinitions(models.Model):
    class Meta:
        abstract = True

    @property
    def sections(self):
        raise NotImplementedError

    @cached_property
    def definitions(self) -> [Dict, Dict]:
        words = {}
        word_freq = {}

        word_re = re.compile(r'(\w+-\w+|\w+)')
        morph = pymorphy2.MorphAnalyzer()
        glosbe_api = GlosbeAPI()

        for section in self.sections.all():
            text = BeautifulSoup(section.body, features='html.parser').get_text()

            for word in text.split():
                word_match = word_re.match(word)

                if word_match:
                    word = word_match.group(0)

                word_freq.setdefault(word, 0)
                word_freq[word] += 1

                parsed_word = morph.parse(word)[0]
                normalized_word = parsed_word.normal_form

                definitions = list(glosbe_api.translate(normalized_word).definitions.values())

                words[normalized_word] = None

                if definitions:
                    meanings = definitions[0].meanings

                    if meanings:
                        words[normalized_word] = []

                        for i in range(0, 3):
                            try:
                                meaning = meanings[i]

                                if meaning['language'] != 'en':
                                    continue

                                words[normalized_word].append(meaning)
                            except IndexError:
                                break

        return words, word_freq
