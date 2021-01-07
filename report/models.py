import copy

from typing import AbstractSet, Dict, TypeVar

from django.db import models

from text.models import TextDifficulty, Text, TextSection

from django.utils import timezone


Student = TypeVar('Student')


# --------------------To be removed--------------------------------
# We'll be replacing this with text_complete
class StudentPerformance(models.Model):
    id = models.BigIntegerField(primary_key=True)
    student = models.ForeignKey('user.Student', on_delete=models.DO_NOTHING)

    text = models.ForeignKey(Text, on_delete=models.DO_NOTHING)
    text_reading = models.ForeignKey('text_reading.StudentTextReading', on_delete=models.DO_NOTHING)
    text_section = models.ForeignKey(TextSection, on_delete=models.DO_NOTHING)

    start_dt = models.DateTimeField()
    end_dt = models.DateTimeField()

    state = models.CharField(max_length=64)

    text_difficulty_slug = models.SlugField(blank=False)

    answered_correctly = models.IntegerField()
    attempted_questions = models.IntegerField()

    @property
    def percentage_correct(self):
        return self.answered_correctly / self.attempted_questions

    class Meta:
        managed = False
        db_table = 'report_student_performance'

    def __str__(self):
        return str(self.student) + ' ' + 'scored ' + str(self.percentage_correct * 100) + '%'
# ----------------------------------------------------

class StudentReadingsInProgress(models.Model):
    id = models.BigIntegerField(primary_key=True)
    student = models.ForeignKey('user.Student', on_delete=models.DO_NOTHING)

    text = models.ForeignKey(Text, on_delete=models.DO_NOTHING)
    text_reading = models.ForeignKey('text_reading.StudentTextReading', on_delete=models.DO_NOTHING)

    start_dt = models.DateTimeField()

    text_difficulty_slug = models.SlugField(blank=False)

    class Meta:
        managed = False
        db_table = 'report_texts_in_progress'


class StudentReadingsComplete(models.Model):
    id = models.BigIntegerField(primary_key=True)
    student = models.ForeignKey('user.Student', on_delete=models.DO_NOTHING)

    text = models.ForeignKey(Text, on_delete=models.DO_NOTHING)
    text_reading = models.ForeignKey('text_reading.StudentTextReading', on_delete=models.DO_NOTHING)

    start_dt = models.DateTimeField()
    end_dt = models.DateTimeField()

    text_difficulty_slug = models.SlugField(blank=False)

    class Meta:
        managed = False
        db_table = 'report_texts_complete'


class StudentPerformanceReport(object):
    def __init__(self, student: Student, *args, **kwargs):
        self.student = student
        # different database views, different querysets
        self.queryset_in_progress = StudentReadingsInProgress.objects.filter(student=self.student)
        self.queryset_complete = StudentReadingsComplete.objects.filter(student=self.student)

    @property
    def today_dt(self):
        return timezone.now()

    @property
    def first_of_current_month(self):
        return self.today_dt.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    @property
    def first_of_next_month(self):
        if self.first_of_current_month.month == 12:
            return self.first_of_current_month.replace(year=self.first_of_current_month.year+1, month=1)
        else:
            return self.first_of_current_month.replace(month=self.first_of_current_month.month+1)

    @property
    def first_of_last_month(self):
        if self.first_of_current_month.month == 1:
            return self.first_of_current_month.replace(year=self.today_dt.year-1, month=12)
        else:
            return self.first_of_current_month.replace(month=self.today_dt.month-1)

    @property
    def cumulative_complete(self):
        return self.queryset_complete

    @property
    def cumulative_in_progress(self):
        return self.queryset_in_progress

    @property
    def current_month_complete(self):
        return self.queryset_complete.filter(
            end_dt__gte=self.first_of_current_month,
            end_dt__lt=self.first_of_next_month
        )

    @property
    def current_month_in_progress(self):
        return self.queryset_in_progress.filter(
            start_dt__gte=self.first_of_current_month,
            start_dt__lt=self.first_of_next_month
        )

    @property
    def past_month_complete(self):
        return self.queryset_complete.filter(
            end_dt__gte=self.first_of_last_month,
            end_dt__lt=self.first_of_current_month
        )

    @property
    def past_month_in_progress(self):
        return self.queryset_in_progress.filter(
            start_dt__gte=self.first_of_last_month,
            start_dt__lt=self.first_of_current_month
        )

    def to_dict(self) -> Dict:

        total_num_of_texts = Text.objects.count()

        categories = {
            'cumulative': {'metrics': {}, 'title': 'Cumulative'},
            'current_month': {'metrics': {}, 'title': 'Current Month'},
            'past_month': {'metrics': {}, 'title': 'Past Month'},
        }

        difficulty_dict = {'title': '', 'categories': categories}

        performance = {'all': difficulty_dict}

        aggregates = {
            'text_readings': models.Count(distinct=True, expression='text')
        }

        performance['all']['title'] = 'All Levels'

        for category in ('cumulative', 'past_month', 'current_month',):
            performance['all']['categories'][category]['metrics']['total_texts'] = total_num_of_texts

        # metrics for texts read to completion        
        performance['all']['categories']['cumulative']['metrics']['complete'] = self.cumulative_complete.aggregate(**aggregates)['text_readings']
        performance['all']['categories']['past_month']['metrics']['complete'] = self.past_month_complete.aggregate(**aggregates)['text_readings']
        performance['all']['categories']['current_month']['metrics']['complete'] = self.current_month_complete.aggregate(**aggregates)['text_readings']

        # metrics for text readings still in progress
        performance['all']['categories']['cumulative']['metrics']['in_progress'] = self.cumulative_in_progress.aggregate(**aggregates)['text_readings']
        performance['all']['categories']['past_month']['metrics']['in_progress'] = self.past_month_in_progress.aggregate(**aggregates)['text_readings']
        performance['all']['categories']['current_month']['metrics']['in_progress'] = self.current_month_in_progress.aggregate(**aggregates)['text_readings']

        
        for difficulty in TextDifficulty.objects.annotate(total_texts=models.Count('texts')).order_by('id').all():
            performance[difficulty.slug] = {
                'title': '',
                'categories': {
                    'cumulative': {
                        'metrics': {
                            'complete': None,
                            'in_progress': None
                        },
                        'title': 'Cumulative'
                    },
                    'current_month': {
                        'metrics': {
                            'complete': None,
                            'in_progress': None
                        },
                        'title': 'Current Month'
                    },
                    'past_month': {
                        'metrics': {
                            'complete': None,
                            'in_progress': None
                        },
                        'title': 'Past Month'
                    }
                }
            }

            performance[difficulty.slug]['title'] = difficulty.name

            for category in ('cumulative', 'past_month', 'current_month',):
                        performance[difficulty.slug]['categories'][category]['metrics']['total_texts'] = difficulty.total_texts

            performance[difficulty.slug]['categories']['cumulative']['metrics']['complete'] = self.cumulative_complete.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)['text_readings']

            performance[difficulty.slug]['categories']['past_month']['metrics']['complete'] = self.past_month_complete.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)['text_readings']

            performance[difficulty.slug]['categories']['current_month']['metrics']['complete'] = self.current_month_complete.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)['text_readings']

            performance[difficulty.slug]['categories']['cumulative']['metrics']['in_progress'] = self.cumulative_in_progress.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)['text_readings']

            performance[difficulty.slug]['categories']['past_month']['metrics']['in_progress'] = self.past_month_in_progress.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)['text_readings']

            performance[difficulty.slug]['categories']['current_month']['metrics']['in_progress'] = self.current_month_in_progress.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)['text_readings']

        return performance