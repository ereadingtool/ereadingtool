import copy

from typing import AbstractSet, Dict, TypeVar

from django.db import models

from text.models import TextDifficulty, Text, TextSection

from django.utils import timezone


Student = TypeVar('Student')


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


class StudentPerformanceReport(object):
    def __init__(self, student: Student, *args, **kwargs):
        self.student = student
        self.queryset = StudentPerformance.objects.filter(student=self.student)


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
    def cumulative(self):
        return self.queryset

    @property
    def current_month(self):
        return self.queryset.filter(
            end_dt__gte=self.first_of_current_month,
            end_dt__lt=self.first_of_next_month
        )

    @property
    def past_month(self):
        return self.queryset.filter(
            end_dt__gte=self.first_of_last_month,
            end_dt__lt=self.first_of_current_month
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
            'percent_correct': (models.Sum('answered_correctly', output_field=models.FloatField()) /
                                models.Sum('attempted_questions', output_field=models.FloatField())) * 100,
            'texts_complete': models.Count(distinct=True, expression='text')
        }
        
        performance['all']['categories']['cumulative']['metrics'] = self.cumulative.aggregate(**aggregates)
        performance['all']['categories']['past_month']['metrics'] = self.past_month.aggregate(**aggregates)
        performance['all']['categories']['current_month']['metrics'] = self.current_month.aggregate(**aggregates)

        
        for category in ('cumulative', 'past_month', 'current_month',):
            try:
                performance['all']['categories'][category]['metrics']['percent_correct'] = round(
                    performance['all']['categories'][category]['metrics']['percent_correct'], 2)
            except TypeError as te:
                pass

            performance['all']['categories'][category]['metrics']['total_texts'] = total_num_of_texts

        performance['all']['title'] = 'All Levels'
        
        for difficulty in TextDifficulty.objects.annotate(total_texts=models.Count('texts')).order_by('id').all():
            performance[difficulty.slug] = {
                'title': '',
                'categories': {
                    'cumulative': {
                        'metrics': {
                            'percent_correct': None, 
                            'texts_complete': None,
                        },
                        'title': 'Cumulative'
                    },
                    'current_month': {
                        'metrics': {
                            'percent_correct': None,
                            'texts_complete': None,
                        },
                        'title': 'Current Month'
                    },
                    'past_month': {
                        'metrics': {
                            'percent_correct': None,
                            'texts_complete': None
                        },
                        'title': 'Past Month'
                    }
                }
            }

            performance[difficulty.slug]['title'] = difficulty.name


            performance[difficulty.slug]['categories']['cumulative']['metrics'] = self.cumulative.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)

            performance[difficulty.slug]['categories']['cumulative']['metrics']['total_texts'] = difficulty.total_texts

            try:
                performance[difficulty.slug]['categories']['cumulative']['metrics']['percent_correct'] = round(
                    performance[difficulty.slug]['categories']['cumulative']['metrics']['percent_correct'], 2)
            except TypeError:
                pass

            performance[difficulty.slug]['categories']['past_month']['metrics'] = self.past_month.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)

            performance[difficulty.slug]['categories']['past_month']['metrics']['total_texts'] = difficulty.total_texts

            try:
                performance[difficulty.slug]['categories']['past_month']['metrics']['percent_correct'] = round(
                    performance[difficulty.slug]['categories']['past_month']['metrics']['percent_correct'], 2)
            except TypeError:
                pass

            performance[difficulty.slug]['categories']['current_month']['metrics'] = self.current_month.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)

            performance[difficulty.slug]['categories']['current_month']['metrics']['total_texts'] = difficulty.total_texts

            try:
                performance[difficulty.slug]['categories']['current_month']['metrics']['percent_correct'] = round(
                    performance[difficulty.slug]['categories']['current_month']['metrics']['percent_correct'], 2)
            except TypeError:
                pass

        return performance
