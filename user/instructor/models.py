from typing import Dict, Optional

from django.db import models
from django.db.models import Q
from django.urls import reverse_lazy
from django.utils import timezone

from user.models import ReaderUser
from user.mixins.models import Profile

from text.models import Text
from text_reading.base import TextReadingStateMachine


class Instructor(Profile, models.Model):
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
        text_student_summary = text.to_student_summary_dict()

        text_student_summary['text_sections_complete'] = self.sections_complete_for(text)
        text_student_summary['last_read_dt'] = self.last_read(text)

        return text_student_summary

    def last_read(self, text: Text) -> Optional[timezone.datetime]:
        last_read_dt = None

        if self.text_readings.filter(text=text).exists():
            last_reading = self.text_readings.filter(text=text).order_by('-start_dt')[0]

            if last_reading.last_read_dt:
                last_read_dt = last_reading.last_read_dt.isoformat()

        return last_read_dt

    def sections_complete_for(self, text: Text) -> int:
        sections_complete = 0

        if self.text_readings.exclude(state=TextReadingStateMachine.complete.name).filter(text=text).exists():
            current_text_reading = self.text_readings.exclude(
                state=TextReadingStateMachine.complete.name).get(text=text)

            if not current_text_reading.state_machine.is_intro:
                sections_complete = current_text_reading.current_section.order

        return sections_complete

    def __str__(self):
        return self.user.username
