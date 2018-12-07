from typing import TypeVar
from django.db import models

from text_reading.state.models import TextReadingStateMachine

Student = TypeVar('Student')
Instructor = TypeVar('Instructor')


class TextWithInstructorReadingsQuerySet(models.QuerySet):
    def where_instructor(self, instructor: Instructor) -> models.QuerySet:
        return self.filter(instructortextreading__instructor=instructor)


class TextWithInstructorReadingsManager(models.Manager):
    def get_queryset(self):
        state_cls = TextReadingStateMachine
        queryset = TextWithInstructorReadingsQuerySet(self.model, using=self._db).prefetch_related(
            'instructortextreading_set')

        queryset = queryset.annotate(
            num_of_readings=models.Count('instructortextreading'),

            num_of_complete=models.Count('instructortextreading',
                                         filter=models.Q(instructortextreading__state=state_cls.complete.name)),

            num_of_in_progress=models.Count('instructortextreading', filter=models.Q(
                instructortextreading__state=state_cls.in_progress.name) | models.Q(
                instructortextreading__state=state_cls.intro.name))
        )

        return queryset

    def where_instructor(self, instructor: Instructor):
        return self.get_queryset().where_instructor(instructor)


class TextWithStudentReadingsQuerySet(models.QuerySet):
    def where_student(self, student: Student) -> models.QuerySet:
        return self.filter(studenttextreading__student=student)


class TextWithStudentReadingsManager(models.Manager):
    def get_queryset(self):
        state_cls = TextReadingStateMachine
        queryset = TextWithStudentReadingsQuerySet(self.model, using=self._db).prefetch_related('studenttextreading_set')

        queryset = queryset.annotate(
            num_of_readings=models.Count('studenttextreading'),

            num_of_complete=models.Count('studenttextreading',
                                         filter=models.Q(studenttextreading__state=state_cls.complete.name)),

            num_of_in_progress=models.Count('studenttextreading', filter=models.Q(
                                                   studenttextreading__state=state_cls.in_progress.name) | models.Q(
                                                   studenttextreading__state=state_cls.intro.name))
        )

        return queryset

    def where_student(self, student: Student):
        return self.get_queryset().where_student(student)
