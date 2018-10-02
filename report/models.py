from typing import Dict

from django.db import models

from text.models import TextDifficulty, Text, TextSection
from text_reading.student.models import StudentTextReading
from user.student.models import Student


class StudentPerformance(models.Model):
    student = models.ForeignKey(Student, on_delete=models.DO_NOTHING)

    text = models.ForeignKey(Text, on_delete=models.DO_NOTHING)
    text_reading = models.ForeignKey(StudentTextReading, on_delete=models.DO_NOTHING)
    text_section = models.ForeignKey(TextSection, on_delete=models.DO_NOTHING)

    start_dt = models.DateTimeField()
    end_dt = models.DateTimeField()

    text_difficulty_slug = models.SlugField(blank=False)

    percentage_correct = models.FloatField()

    class Meta:
        managed = False
        db_table = 'report_student_performance'

    def to_dict(self) -> Dict:
        performance = {}

        return performance
