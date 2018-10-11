from django.db import models


class TextDefinitions(models.Model):
    pass


class TextWord(models.Model):
    definitions = models.ForeignKey(TextDefinitions, related_name='words', on_delete=models.CASCADE)

    normal_form = models.CharField(max_length=128, blank=False)


class TextWordMeaning(models.Model):
    word = models.ForeignKey(TextWord, related_name='meanings', on_delete=models.CASCADE)

    pos = models.CharField(max_length=32, blank=False)
    text = models.TextField(blank=False)
