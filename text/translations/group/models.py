from typing import AnyStr, Optional

from django.db import models

from text.translations.models import TextWord
from text.phrase.models import TextPhrase


class TextWordGroup(TextPhrase):
    word_type = 'compound'

    @property
    def phrase(self):
        return ' '.join([component.word.word for component in self.components.order_by('order')])


class TextGroupWord(models.Model):
    class Meta:
        unique_together = (('group', 'word', 'order'),)

    group = models.ForeignKey(TextWordGroup, related_name='components', on_delete=models.CASCADE)
    word = models.OneToOneField(TextWord, related_name='group_word', on_delete=models.CASCADE)

    order = models.IntegerField(default=0)
