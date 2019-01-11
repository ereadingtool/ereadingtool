import os

from typing import Tuple

from django.db import models

from text.models import Text

from text_reading.base import TextReading, TextReadingAnswers
from user.student.models import Student


class StudentTextReading(TextReading, models.Model):
    student = models.ForeignKey(Student, null=False, on_delete=models.CASCADE, related_name='text_readings')

    @classmethod
    def start(cls, student: Student, text: Text) -> 'StudentTextReading':
        """

        :param student:
        :param text:
        :return: TextReading
        """

        text_reading = cls.objects.create(student=student, text=text, random_seed=os.urandom(256))

        return text_reading

    @classmethod
    def resume(cls, student: Student, text: Text) -> 'StudentTextReading':
        """

        :param student:
        :param text:
        :return: TextReading
        """
        return cls.objects.filter(student=student,
                                  text=text).exclude(state=cls.state_machine_cls.complete.name).get()

    @classmethod
    def start_or_resume(cls, student: Student, text: Text) -> Tuple[bool, 'StudentTextReading']:
        """

        :param student:
        :param text:
        :return: TextReading
        """
        existing_reading = cls.objects.filter(student=student, text=text).exclude(
            state=cls.state_machine_cls.complete.name).exists()

        if existing_reading:
            text_reading = cls.resume(student=student, text=text)
        else:
            text_reading = cls.start(student=student, text=text)

        return (not existing_reading), text_reading

    @property
    def text_reading_answer_cls(self):
        return StudentTextReadingAnswers


class StudentTextReadingAnswers(TextReadingAnswers, models.Model):
    text_reading = models.ForeignKey(StudentTextReading, on_delete=models.CASCADE,
                                     related_name='text_reading_answers')
