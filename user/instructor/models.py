from typing import Dict
from django.db import models
from django.db.models import Q
from django.urls import reverse_lazy

from text.models import Text
from user.mixins.models import Profile, TextReadings
from user.models import ReaderUser


class Instructor(Profile, TextReadings, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)

    login_url = reverse_lazy('instructor-login')

    @property
    def text_search_queryset(self):
        return Text.objects_with_instructor_readings

    @property
    def text_search_queryset_for_user(self):
        return self.text_search_queryset.where_instructor(self)

    def to_dict(self):
        return {
            'id': self.pk,
            'username': self.user.username,
            'texts': [text.to_instructor_summary_dict()
                      for text in self.created_texts.model.objects.filter(
                    Q(created_by=self) | Q(last_modified_by=self))]
        }

    def to_text_summary_dict(self, text: Text) -> Dict:
        text_instructor_summary = text.to_student_summary_dict()

        text_instructor_summary['text_sections_complete'] = self.sections_complete_for(text)
        text_instructor_summary['last_read_dt'] = self.last_read_dt(text)
        text_instructor_summary['questions_correct'] = self.last_read_questions_correct(text)

        return text_instructor_summary

    def __str__(self):
        return self.user.username
