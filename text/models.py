from django.db import models


class TextDifficulty(models.Model):
    class Meta:
        verbose_name_plural = 'Text Difficulties'

    slug = models.SlugField(blank=False)
    name = models.CharField(max_length=255, blank=False)

    def __str__(self):
        return self.name


class Text(models.Model):
    source = models.CharField(max_length=255, blank=False)
    difficulty = models.ForeignKey(TextDifficulty, null=True, related_name='texts', on_delete=models.SET_NULL)

    body = models.TextField(blank=False)

    def __str__(self):
        return '{pk} - {source}'.format(pk=self.pk, source=self.source)

