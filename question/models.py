from django.db import models
from text.models import Text


class Question(models.Model):
    text = models.ForeignKey(Text, blank=False, related_name='questions', on_delete=models.CASCADE)

    TYPE_CHOICES = (
        ('main_idea', 'Main Idea'),
        ('detail', 'Detail')
    )

    type = models.CharField(max_length=32, blank=False, choices=TYPE_CHOICES)


class Answer(models.Model):
    question = models.ForeignKey(Question, blank=False, related_name='answers', on_delete=models.CASCADE)

    text = models.CharField(max_length=255, blank=False)
    correct = models.BooleanField(default=False, blank=False)
    feedback = models.CharField(max_length=255, blank=False)

