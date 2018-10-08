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
    def definitions(self) -> Dict:
        words = {}

        word_re = re.compile(r'(\w+)')
        morph = pymorphy2.MorphAnalyzer()
        glosbe_api = GlosbeAPI()

        for section in self.sections.all():
            text = BeautifulSoup(section.body).get_text()

            for word in text.split():
                word_match = word_re.match(word)

                if word_match:
                    word = word_match.group(0)

                parsed_word = morph.parse(word)[0]
                normalized_word = parsed_word.normal_form

                definitions = list(glosbe_api.translate(normalized_word).definitions.values())

                if definitions:
                    meanings = definitions[0].meanings

                    if meanings:
                        words[normalized_word] = meanings[0]
                    else:
                        words[normalized_word] = None
                else:
                    words[normalized_word] = None

        return words