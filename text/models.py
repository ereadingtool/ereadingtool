from django.db import models
from mixins.model import Timestamped
from quiz.models import Quiz


class TextDifficulty(models.Model):
    class Meta:
        verbose_name_plural = 'Text Difficulties'

    slug = models.SlugField(blank=False)
    name = models.CharField(max_length=255, blank=False)

    def __str__(self):
        return self.name

    def to_dict(self):
        return {
            'slug': self.slug,
            'name': self.name
        }

    @classmethod
    def setup_default(cls):
        for params in [('intermediate_mid', 'Intermediate-Mid'), ('advanced_low', 'Advanced-Low'),
                       ('advanced_mid', 'Advanced-Mid'), ('intermediate_high', 'Intermediate-High')]:
            if not TextDifficulty.objects.filter(slug=params[0], name=params[1]).count():
                difficulty = TextDifficulty.objects.create(slug=params[0], name=params[1])
                difficulty.save()


class Text(Timestamped, models.Model):
    quiz = models.ForeignKey(Quiz, related_name='texts', on_delete=models.CASCADE)

    source = models.CharField(max_length=255, blank=False)
    difficulty = models.ForeignKey(TextDifficulty, null=True, related_name='texts', on_delete=models.SET_NULL)

    body = models.TextField(blank=False)

    title = models.CharField(max_length=255, blank=True)
    author = models.CharField(max_length=255, blank=True)

    def to_dict(self):
        questions = [question.to_dict() for question in self.questions.all()]
        questions_count = len(list(questions))

        return {
            'id': self.pk,
            'title': self.title,
            'created_dt': self.created_dt.isoformat(),
            'modified_dt': self.modified_dt.isoformat(),
            'question_count': questions_count,
            'questions': questions,
            'source': self.source,
            'difficulty': self.difficulty.slug,
            'body': self.body,
            'author': self.author
        }

    def __str__(self):
        return '{title}'.format(title=self.title)
