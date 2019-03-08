from django.db import models

from text.phrase.models import TextPhrase
from text.translations.models import TextWord


class TextWordGroup(TextPhrase):
    pass


class TextGroupWord(models.Model):
    class Meta:
        unique_together = (('group', 'word', 'order'),)

    group = models.ForeignKey(TextWordGroup, related_name='components', on_delete=models.CASCADE)
    word = models.OneToOneField(TextWord, related_name='group_word', on_delete=models.CASCADE)

    order = models.IntegerField(default=0)
