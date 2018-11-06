from django.db import models


class TextDefinitions(models.Model):
    def to_dict(self, all_translations=False):
        translations_filter_by = dict()

        if not all_translations:
            translations_filter_by['correct_for_context'] = True

        return {
            word.word: {
                'grammemes': word.grammemes,
                'translation': [translation.phrase for translation in
                                word.translations.filter(**translations_filter_by)]
            } for word in self.words.prefetch_related('translations').all()
        }

    def __str__(self):
        return f'{self.__class__.__name__} {self.words.count()} words for section {self.text_section}'


class TextWord(models.Model):
    class Meta:
        unique_together = (('instance', 'word', 'definitions'),)

    definitions = models.ForeignKey(TextDefinitions, related_name='words', on_delete=models.CASCADE)

    instance = models.IntegerField(default=0)
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
        translation = None

        try:
            translation = self.translations.filter(correct_for_context=True)[0]
        except IndexError:
            pass

        return {
            'word': self.word,
            'grammemes': self.grammemes,
            'translation': translation.phrase if translation else None
        }


class TextWordTranslation(models.Model):
    word = models.ForeignKey(TextWord, related_name='translations', on_delete=models.CASCADE)
    correct_for_context = models.BooleanField(default=False)

    phrase = models.TextField()

    def __str__(self):
        return f'{self.word} - {self.phrase}'
