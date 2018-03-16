from django.db import models


class TextDifficulty(models.Model):
    code = models.CharField(max_length=32, blank=False)
    name = models.CharField(max_length=255, blank=False)


class Text(models.Model):
    source = models.CharField(max_length=255, blank=False)
    difficulty = models.ForeignKey(TextDifficulty, null=True, related_name='texts', on_delete=models.SET_NULL)
