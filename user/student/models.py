from typing import Dict, Optional

from django.db import models
from django.template import loader
from django.urls import reverse_lazy, reverse
from django.utils import timezone

from flashcards.models import Flashcards
from report.models import StudentPerformanceReport
from text.models import TextDifficulty, Text
from text_reading.base import TextReadingStateMachine
from user.mixins.models import Profile
from user.models import ReaderUser


class Student(Profile, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    difficulty_preference = models.ForeignKey(TextDifficulty, null=True, on_delete=models.SET_NULL,
                                              related_name='students')

    flashcards = models.OneToOneField(Flashcards, null=True, blank=True, related_name='student',
                                      on_delete=models.SET_NULL)

    login_url = reverse_lazy('student-login')

    @property
    def text_search_queryset(self):
        return Text.objects_with_student_readings

    @property
    def text_search_queryset_for_user(self):
        return self.text_search_queryset.where_student(self)

    @property
    def performance(self):
        return StudentPerformanceReport(student=self)

    def to_dict(self):
        difficulties = [(text_difficulty.slug, text_difficulty.name)
                        for text_difficulty in TextDifficulty.objects.all()]

        # difficulty_preference can be null
        difficulties.append(('', ''))

        performance_report_html = loader.render_to_string('student_performance_report.html',
                                                          {'performance_report': self.performance.to_dict()})

        performance_report_pdf_link = reverse('student-performance-pdf-link', kwargs={'pk': self.pk})

        return {
            'id': self.pk,
            'username': self.user.username,
            'email': self.user.email,
            'difficulty_preference': [self.difficulty_preference.slug, self.difficulty_preference.name]
            if self.difficulty_preference else None,
            'difficulties': difficulties,
            'performance_report': {'html': performance_report_html, 'pdf_link': performance_report_pdf_link},
            'flashcards': self.flashcards.to_dict() if self.flashcards else None
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

