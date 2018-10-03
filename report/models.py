from typing import Dict, TypeVar

from django.db import models

from text.models import TextDifficulty, Text, TextSection

from django.utils import timezone


class StudentPerformance(models.Model):
    id = models.BigIntegerField(primary_key=True)
    student = models.ForeignKey('user.Student', on_delete=models.DO_NOTHING)

    text = models.ForeignKey(Text, on_delete=models.DO_NOTHING)
    text_reading = models.ForeignKey('text_reading.StudentTextReading', on_delete=models.DO_NOTHING)
    text_section = models.ForeignKey(TextSection, on_delete=models.DO_NOTHING)

    start_dt = models.DateTimeField()
    end_dt = models.DateTimeField()

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
    def __init__(self, student: TypeVar('Student'), *args, **kwargs):
        self.student = student

    @property
    def today_dt(self):
        return timezone.now()

    @property
    def first_of_current_month(self):
        return self.today_dt.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    @property
    def first_of_next_month(self):
        return self.today_dt.replace(month=self.today_dt.month+1).replace(day=1, hour=0, minute=0, second=0,
                                                                          microsecond=0)

    @property
    def first_of_last_month(self):
        return self.today_dt.replace(day=1, month=self.today_dt.month-1)

    @property
    def cumulative(self):
        return StudentPerformance.objects.filter(student=self.student)

    @property
    def current_month(self):
        return StudentPerformance.objects.filter(
            student=self.student,
            end_dt__gte=self.first_of_current_month,
            end_dt__lt=self.first_of_next_month)

    @property
    def past_month(self):
        return StudentPerformance.objects.filter(
            student=self.student,
            end_dt__gte=self.first_of_last_month,
            end_dt__lt=self.first_of_current_month)

    def to_dict(self) -> Dict:
        categories = {'cumulative': {}, 'current_month': {}, 'past_month': {}}
        performance = {'all': categories}

        aggregates = {
            'percent_correct': (models.Sum('answered_correctly', output_field=models.FloatField()) /
                                models.Sum('attempted_questions', output_field=models.FloatField())),

            'texts_complete': models.Count(distinct=True, expression='text')
        }

        for difficulty in TextDifficulty.objects.all():
            performance.setdefault(difficulty.slug, {})

        performance['all']['cumulative'] = self.cumulative.aggregate(**aggregates)
        performance['all']['past_month'] = self.past_month.aggregate(**aggregates)
        performance['all']['current_month'] = self.current_month.aggregate(**aggregates)

        for difficulty in TextDifficulty.objects.all():
            performance.setdefault(difficulty.slug, categories)

            performance[difficulty.slug]['cumulative'] = self.cumulative.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)
            performance[difficulty.slug]['past_month'] = self.past_month.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)
            performance[difficulty.slug]['current_month'] = self.current_month.filter(
                text_difficulty_slug=difficulty.slug).aggregate(**aggregates)

        return performance
