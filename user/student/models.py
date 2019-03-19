from typing import Dict, List, Tuple, AnyStr, TypeVar

from django.db import models
from django.template import loader
from django.urls import reverse_lazy, reverse

from report.models import StudentPerformanceReport
from text.models import TextDifficulty, Text
from text.phrase.models import TextPhrase
from user.mixins.models import Profile, TextReadings
from user.models import ReaderUser


class Student(Profile, TextReadings, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    difficulty_preference = models.ForeignKey(TextDifficulty, null=True, on_delete=models.SET_NULL,
                                              related_name='students')

    login_url = reverse_lazy('student-login')

    @property
    def text_search_queryset(self) -> models.QuerySet:
        return Text.objects_with_student_readings

    @property
    def text_search_queryset_for_user(self) -> models.QuerySet:
        return self.text_search_queryset.where_student(self)

    @property
    def unread_text_queryset(self) -> models.QuerySet:
        return self.text_search_queryset.exclude(studenttextreading__student=self)

    @property
    def performance(self) -> 'StudentPerformanceReport':
        return StudentPerformanceReport(student=self)

    def serialized_flashcards(self) -> List[Tuple]:
        return [
            (flashcard.phrase, flashcard.to_dict()) for flashcard in self.flashcards.all()
        ]

    def to_dict(self) -> Dict:
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
            'flashcards': self.serialized_flashcards()
        }

    def to_text_summary_dict(self, text: Text) -> Dict:
        text_student_summary = text.to_student_summary_dict()

        text_student_summary['text_sections_complete'] = self.sections_complete_for(text)
        text_student_summary['last_read_dt'] = self.last_read_dt(text)
        text_student_summary['questions_correct'] = self.last_read_questions_correct(text)

        return text_student_summary

    def __str__(self) -> AnyStr:
        return self.user.username

    def has_flashcard_for_phrase(self, text_phrase: TextPhrase) -> bool:
        return self.flashcards.filter(text_phrase=text_phrase).exists()

    def add_to_flashcards(self, text_phrase: TextPhrase):
        flashcard, created = self.flashcards.objects.get_or_create(student=self, phrase=text_phrase)

        return flashcard

    def remove_from_flashcards(self, text_phrase: TextPhrase):
        self.flashcards.filter(text_phrase=text_phrase).delete()

    def get_or_create_flashcard_session(self):
        return self.flashcard_session.objects.get_or_create(student=self)
