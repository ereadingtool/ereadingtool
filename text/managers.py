from typing import TypeVar
from django.db import models

from text_reading.state.models import TextReadingStateMachine

Student = TypeVar('Student')


class TextWithReadingsQuerySet(models.QuerySet):
    def where_student(self, student: Student):
        return self.filter(studenttextreading__student=student)


class TextWithReadingsManager(models.Manager):
    def get_queryset(self):
        state_cls = TextReadingStateMachine
        queryset = TextWithReadingsQuerySet(self.model, using=self._db).prefetch_related('studenttextreading_set')

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
