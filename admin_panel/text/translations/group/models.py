from typing import AnyStr

from django.db import models

from text.phrase.models import TextPhrase
from text.translations.models import TextWord


class TextWordGroup(TextPhrase):
    def to_text_reading_dict(self):
        text_reading_dict = super(TextWordGroup, self).to_text_reading_dict()

        text_reading_dict['word'] = (text_reading_dict['word_type'], text_reading_dict['group'])

        return text_reading_dict


class TextGroupWord(models.Model):
    class Meta:
        unique_together = (('group', 'word', 'order'),)

    group = models.ForeignKey(TextWordGroup, related_name='components', on_delete=models.CASCADE)
    word = models.OneToOneField(TextWord, related_name='group_word', on_delete=models.CASCADE)

    order = models.IntegerField(default=0)

    def __str__(self) -> AnyStr:
        return f'{self.word.phrase} {self.order} of {self.group.components.count()} group {self.group.pk}'
