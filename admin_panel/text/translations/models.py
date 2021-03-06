from django.db import models

from text.phrase.models import TextPhrase


class TextWord(TextPhrase):
    @classmethod
    def create(cls, **params) -> 'TextWord':
        return TextWord.objects.create(**params)

    def to_dict(self):
        text_word_dict = super(TextWord, self).to_dict()

        try:
            text_word_dict['group'] = {
                'group': self.group_word.group_id,
                'order': self.group_word.order
            }
        except models.ObjectDoesNotExist:
            text_word_dict['group'] = None

        return text_word_dict

    def to_translations_dict(self):
        translation_dict = super(TextWord, self).to_translations_dict()

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

    def to_text_reading_dict(self):
        text_reading_dict = super(TextWord, self).to_text_reading_dict()

        text_reading_dict['word'] = (text_reading_dict['word_type'], text_reading_dict['group'])

        return text_reading_dict
