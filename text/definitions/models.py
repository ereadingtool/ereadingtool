from django.db import models


class TextDefinitions(models.Model):
    def to_dict(self):
        return {
            word.word: {
                'grammemes': word.grammemes,
                'meaning': [meanings.text for meanings in word.meanings.filter(correct_for_context=True)]
            } for word in self.words.prefetch_related('meanings').all()
        }

    def __str__(self):
        return f'{self.__class__.__name__} {self.words.count()} words for section {self.text_section}'


class TextWord(models.Model):
    class Meta:
        unique_together = (('instance', 'word', 'definitions'),)

    definitions = models.ForeignKey(TextDefinitions, related_name='words', on_delete=models.CASCADE)

    instance = models.IntegerField(default=0, null=False)
    word = models.CharField(max_length=128, blank=False)

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
        return f'{self.word} ({self.pos, self.tense, self.aspect, self.form, self.mood})'

    def to_dict(self):
        meaning = None

        try:
            meaning = self.meanings.filter(correct_for_context=True)[0]
        except IndexError:
            pass

        return {
            'word': self.word,
            'grammemes': self.grammemes,
            'meaning': meaning.text if meaning else None
        }


class TextWordMeaning(models.Model):
    word = models.ForeignKey(TextWord, related_name='meanings', on_delete=models.CASCADE)
    correct_for_context = models.BooleanField(default=False, null=False)

    text = models.TextField(blank=False)

    def __str__(self):
        return f'{self.word} - {self.text}'
