from django.db import models
from mixins.model import Timestamped
from text.models import TextSection


class Question(Timestamped, models.Model):
    text_section = models.ForeignKey(TextSection, blank=False, related_name='questions', on_delete=models.CASCADE)

    body = models.TextField(blank=False)
    order = models.PositiveIntegerField(default=0, editable=False)

    TYPE_CHOICES = (
        ('main_idea', 'Main Idea'),
        ('detail', 'Detail')
    )

    type = models.CharField(max_length=32, blank=False, choices=TYPE_CHOICES)

    def __str__(self):
        return self.body[:15]

    def to_dict(self):
        return {
            'id': self.pk,
            'text_section_id': self.text_section.pk,
            'created_dt': self.created_dt.isoformat(),
            'modified_dt': self.modified_dt.isoformat(),
            'body': self.body,
            'order': self.order,
            'answers': [answer.to_dict() for answer in self.answers.all()],
            'question_type': self.type
        }


class Answer(models.Model):
    class Meta:
        ordering = ['order']

    order = models.PositiveIntegerField(default=0, editable=False)

    question = models.ForeignKey(Question, blank=False, related_name='answers', on_delete=models.CASCADE)

    text = models.CharField(max_length=2048, blank=False)
    correct = models.BooleanField(default=False, blank=False)
    feedback = models.CharField(max_length=2048, blank=False)

    def __str__(self):
        return f'{self.order}'

    def to_dict(self):
        return {
            'id': self.pk,
            'question_id': self.question_id,
            'text': self.text,
            'order': self.order,
            'feedback': self.feedback,
            'correct': self.correct
        }
