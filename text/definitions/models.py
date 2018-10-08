import re
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
            for word in section.body.split('\s'):
                word_match = word_re.match(word)

                if word_match:
                    word = word_match.group(0)

                parsed_word = morph.parse(word)[0]
                normalized_word = parsed_word.normal_form

                definitions = list(glosbe_api.translate(normalized_word).definitions.values())

                words[normalized_word] = definitions[0].meanings

        return words
