from django.db import models


class TextDefinitions(models.Model):
    pass


class TextWord(models.Model):
    definitions = models.ForeignKey(TextDefinitions, related_name='words', on_delete=models.CASCADE)

    normal_form = models.CharField(max_length=128, blank=False)

    pos = models.CharField(max_length=32, null=True, blank=True)
    tense = models.CharField(max_length=32, null=True, blank=True)
    aspect = models.CharField(max_length=32, null=True, blank=True)
    form = models.CharField(max_length=32, null=True, blank=True)
    mood = models.CharField(max_length=32, null=True, blank=True)

    def __str__(self):
        return f'{self.normal_form} ({self.pos, self.tense, self.aspect, self.form, self.mood})'


class TextWordMeaning(models.Model):
    word = models.ForeignKey(TextWord, related_name='meanings', on_delete=models.CASCADE)

    text = models.TextField(blank=False)

    def __str__(self):
        return f'{self.word} - {self.text}'
