from django.db import models

from django.urls import reverse

from text.translations.models import TextWord
from text.translations.mixins import TextWordGrammemes


class TextWordGroup(TextWordGrammemes, models.Model):
    instance = models.IntegerField(default=0)

    @property
    def phrase(self):
        return ' '.join([component.word.word for component in self.components.order_by('order')])

    def to_translations_dict(self):
        translation_dict = {
            'id': self.pk,
            'instance': self.instance,
            'word': self.phrase,
            'grammemes': None,
            'translations': None,
            'group': None,
            'word_type': 'compound',
            'endpoints': {
                'text_word': reverse('text-word-api', kwargs={'pk': self.pk}),
                'translations': reverse('text-word-translation-api', kwargs={'pk': self.pk})
            }
        }

        return translation_dict


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

    def to_dict(self):
        return {
            'id': self.pk,
            'correct_for_context': self.correct_for_context,
            'text': self.phrase
        }

