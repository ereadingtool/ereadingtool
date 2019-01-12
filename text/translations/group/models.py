from django.db import models

from text.translations.models import TextWord


class TextWordGroup(models.Model):
    pass


class TextGroupWord(models.Model):
    class Meta:
        unique_together = (('group', 'word', 'order'),)

    group = models.ForeignKey(TextWordGroup, related_name='components', on_delete=models.CASCADE)
    word = models.OneToOneField(TextWord, related_name='group_word', on_delete=models.CASCADE)

    order = models.IntegerField(default=0)


class TextWordGroupTranslation(models.Model):
    group = models.ForeignKey(TextWordGroup, related_name='translations', on_delete=models.CASCADE)

    correct_for_context = models.BooleanField(default=False)
    phrase = models.TextField()
