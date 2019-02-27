from typing import AnyStr

from text.translations.group.models import TextWordGroup, TextWordGroupTranslation
from text.translations.models import TextWord, TextWordTranslation


class TextPhrase(object):
    @classmethod
    def get(cls, id: int, word_type: AnyStr):
        if word_type == 'single':
            return TextWord.objects.get(pk=id), TextWordTranslation.create

        elif word_type == 'compound':
            return TextWordGroup.objects.get(pk=id), TextWordGroupTranslation.create
