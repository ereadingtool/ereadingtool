from flashcards.student.models import StudentFlashcard
from typing import Dict, List, Tuple, AnyStr

from django.db import models
from django.urls import reverse_lazy, reverse

from report.models import StudentFlashcardsReport, StudentFlashcardsTable, StudentPerformanceReport, \
                          StudentFlashcardsCSV, StudentFlashcardsHTML
from text.models import TextDifficulty, Text, TextSection
from text.phrase.models import TextPhrase
from user.mixins.models import Profile, TextReadings
from user.models import ReaderUser

from user.student.research_consent.models import StudentResearchConsent


class Student(Profile, TextReadings, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    research_consent = models.OneToOneField(StudentResearchConsent, null=True, on_delete=models.SET_NULL)

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

    @property
    def flashcards_report(self) -> 'StudentFlashcardsReport':
        return StudentFlashcardsReport(student=self)

    @property
    def flashcards_csv(self) -> 'StudentFlashcardsCSV':
        return StudentFlashcardsCSV(student=self)

    @property
    def flashcards_html(self) -> 'StudentFlashcardsHTML':
        return StudentFlashcardsHTML(student=self)

    @property
    def flashcards_table(self) -> 'StudentFlashcardsTable':
        return StudentFlashcardsTable(student=self) 

    @property
    def serialized_flashcards(self) -> List[Tuple]:
        serialized_flashcards = [
            (flashcard.phrase.phrase, flashcard.to_dict()) for flashcard in self.flashcards.all()
        ]

        return serialized_flashcards

    def to_dict(self) -> Dict:
        difficulties = [[text_difficulty.slug, text_difficulty.name]
                        for text_difficulty in TextDifficulty.objects.all()]

        # difficulty_preference can be null
        difficulties.append(['', ''])

        return {
            'id': self.pk,
            'username': self.user.username if self.user.username else None,
            'email': self.user.email,
            'difficulty_preference': [self.difficulty_preference.slug, self.difficulty_preference.name]
            if self.difficulty_preference else None,
            'difficulties': difficulties,
            'uris': {
                'logout_uri': reverse('api-student-logout'),
                'profile_uri': reverse('student-profile')
            }
        }

    def to_text_summary_dict(self, text: Text) -> Dict:
        text_student_summary = text.to_student_summary_dict()
        text_student_summary['vote'] = self.vote_history(text)
        text_student_summary['text_sections_complete'] = self.sections_complete_for(text)
        text_student_summary['last_read_dt'] = self.last_read_dt(text)
        text_student_summary['questions_correct'] = self.last_read_questions_correct(text)

        return text_student_summary

    def __str__(self) -> AnyStr:
        return self.user.username or self.user.email

    def has_flashcard_for_phrase(self, text_phrase: TextPhrase, text_section: TextSection, instance: int) -> bool:
        return self.report_student_flashcards.filter(student=self,
                                                     phrase=text_phrase,
                                                     text_section=text_section,
                                                     instance=instance
                                                     ).exists()

    def add_to_flashcards(self, text_phrase: TextPhrase, text_section: TextSection, instance: int):
        flashcard, created = self.report_student_flashcards.get_or_create(student=self,
                                                                          phrase=text_phrase,
                                                                          text_section=text_section,
                                                                          instance=instance)
        return flashcard

    def remove_from_flashcards(self, text_phrase: TextPhrase, text_section: TextSection, instance: int):
        self.report_student_flashcards.filter(student=self,
                                              phrase=text_phrase,
                                              text_section=text_section,
                                              instance=instance) \
                                      .delete()

    @property
    def is_consenting_to_research(self):
        try:
            if self.research_consent:
                return self.research_consent.active
            else:
                return False
        except StudentResearchConsent.DoesNotExist:
            return False

    def consent_to_research(self, consented: bool):
        if not self.research_consent:
            self.research_consent = StudentResearchConsent.objects.create()
            self.save()

        if consented:
            self.research_consent.on()
        else:
            self.research_consent.off()
