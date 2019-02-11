from django.db import models

from text.translations.models import TextWord


class TextWordGroup(models.Model):
    instance = models.IntegerField(default=0)

    @property
    def phrase(self):
        return ' '.join([component.word.word for component in self.components.order_by('order')])

    def to_translations_dict(self):
        return {
            'id': self.pk,
            'instance': self.instance,
            'translations': [translation.to_dict() for translation in
                             self.translations.all()] or None
        }


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

