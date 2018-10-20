from typing import TypeVar

from django.db import models
from django.urls import reverse_lazy, reverse

from django.template import loader

from text.models import TextDifficulty, Text
from text_reading.base import TextReadingStateMachine
from user.mixins.models import Profile
from user.models import ReaderUser

from report.models import StudentPerformanceReport
from flashcards.models import Flashcards


class Student(Profile, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    difficulty_preference = models.ForeignKey(TextDifficulty, null=True, on_delete=models.SET_NULL,
                                              related_name='students')

    flashcards = models.ForeignKey(Flashcards, null=True, blank=True, related_name='student', on_delete=models.CASCADE)

    login_url = reverse_lazy('student-login')

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
            'text_reading': [text_reading.to_dict() for text_reading in self.text_readings.all()],
            'performance_report': {'html': performance_report_html, 'pdf_link': performance_report_pdf_link}
        }

    def sections_complete_for(self, text: TypeVar('Text')) -> int:
        sections_complete = 0

        if self.text_readings.exclude(state=TextReadingStateMachine.complete.name).filter(text=text).exists():
            current_text_reading = self.text_readings.exclude(
                state=TextReadingStateMachine.complete.name).get(text=text)

            if not current_text_reading.state_machine.is_intro:
                sections_complete = current_text_reading.current_section.order

        return sections_complete

    def __str__(self):
        return self.user.username

