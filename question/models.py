import random

from typing import Dict

from django.db import models

from mixins.model import Timestamped
from text.models import TextSection


class Question(Timestamped, models.Model):
    text_section = models.ForeignKey(TextSection, blank=False, related_name='questions', on_delete=models.CASCADE)

    body = models.TextField()
    order = models.PositiveIntegerField(default=0, editable=False)

    TYPE_CHOICES = (
        ('main_idea', 'Main Idea'),
        ('detail', 'Detail')
    )

    type = models.CharField(max_length=32, blank=False, choices=TYPE_CHOICES)

    def __str__(self):
        return self.body[:15]

    def to_text_reading_dict(self, text_reading=None) -> Dict:
        answers = [answer.to_text_reading_dict(text_reading=text_reading) for answer in self.answers.all()]

        if text_reading:
            random.seed(text_reading.random_seed)
            random.shuffle(answers)

        return {
            'id': self.pk,
            'text_section_id': self.text_section.pk,
            'created_dt': self.created_dt.isoformat(),
            'modified_dt': self.modified_dt.isoformat(),
            'body': self.body,
            'order': self.order,
            'answers': answers,
            'question_type': self.type
        }

    def to_dict(self) -> Dict:
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

    def to_text_reading_dict(self, text_reading=None) -> Dict:
        answer_dict = self.to_dict()

        answer_dict.pop('correct')

        answer_dict['answered_correctly'] = None

        if text_reading and text_reading.text_reading_answers.filter(answer=self).count():
            # this was one of the user's answers
            if self == text_reading.text_reading_answers.filter(question=self.question)[0].answer:
                # answer was given first
                answer_dict['answered_correctly'] = self.correct

            answer_dict['answered_correctly'] = self.correct

        return answer_dict

    def to_dict(self) -> Dict:
        return {
            'id': self.pk,
            'question_id': self.question_id,
            'text': self.text,
            'order': self.order,
            'feedback': self.feedback,
            'correct': self.correct
        }
