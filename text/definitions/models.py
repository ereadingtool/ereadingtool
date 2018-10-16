from django.db import models


class TextDefinitions(models.Model):
    def to_dict(self):
        return {
            word.normal_form: {
                'grammemes': word.grammemes,
                'meaning': [meanings.text for meanings in word.meanings.all()]
            } for word in self.words.prefetch_related('meanings').all()
        }


class TextWord(models.Model):
    definitions = models.ForeignKey(TextDefinitions, related_name='words', on_delete=models.CASCADE)

    normal_form = models.CharField(max_length=128, blank=False)

    pos = models.CharField(max_length=32, null=True, blank=True)
    tense = models.CharField(max_length=32, null=True, blank=True)
    aspect = models.CharField(max_length=32, null=True, blank=True)
    form = models.CharField(max_length=32, null=True, blank=True)
    mood = models.CharField(max_length=32, null=True, blank=True)

    @property
    def grammemes(self):
        return {
            'pos': self.pos,
            'tense': self.tense,
            'aspect': self.aspect,
            'form': self.form,
            'mood': self.mood
        }

    def __str__(self):
        return f'{self.normal_form} ({self.pos, self.tense, self.aspect, self.form, self.mood})'


class TextWordMeaning(models.Model):
    word = models.ForeignKey(TextWord, related_name='meanings', on_delete=models.CASCADE)

    text = models.TextField(blank=False)

    def __str__(self):
        return f'{self.word} - {self.text}'
