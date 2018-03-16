from django.db import models


class TextDifficulty(models.Model):
    class Meta:
        verbose_name_plural = 'Text Difficulties'

    code = models.CharField(max_length=32, blank=False)
    name = models.CharField(max_length=255, blank=False)


class Text(models.Model):
    source = models.CharField(max_length=255, blank=False)
    difficulty = models.ForeignKey(TextDifficulty, null=True, related_name='texts', on_delete=models.SET_NULL)
