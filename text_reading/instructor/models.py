from typing import Tuple

from django.db import models

from text.models import Text

from text_reading.base import TextReading, TextReadingAnswers
from user.instructor.models import Instructor


class InstructorTextReading(TextReading, models.Model):
    instructor = models.ForeignKey(Instructor, null=False, on_delete=models.CASCADE, related_name='text_readings')

    @classmethod
    def start(cls, instructor: Instructor, text: Text) -> 'InstructorTextReading':
        """

        :param instructor:
        :param text:
        :return: TextReading
        """
        text_reading = cls.objects.create(instructor=instructor, text=text)

        return text_reading

    @classmethod
    def resume(cls, instructor: Instructor, text: Text) -> 'InstructorTextReading':
        """

        :param instructor:
        :param text:
        :return: TextReading
        """

        return cls.objects.filter(instructor=instructor,
                                  text=text).exclude(state=cls.state_machine_cls.complete.name).get()

    @classmethod
    def start_or_resume(cls, instructor: Instructor, text: Text) -> Tuple[bool, 'InstructorTextReading']:
        """

        :param instructor:
        :param text:
        :return: TextReading
        """

        existing_reading = cls.objects.filter(instructor=instructor, text=text).exclude(
            state=cls.state_machine_cls.complete.name).exists()

        if existing_reading:
            text_reading = cls.resume(instructor=instructor, text=text)
        else:
            text_reading = cls.start(instructor=instructor, text=text)

        return (not existing_reading), text_reading

    @property
    def text_reading_answer_cls(self):
        return InstructorTextReadingAnswers


class InstructorTextReadingAnswers(TextReadingAnswers, models.Model):
    text_reading = models.ForeignKey(InstructorTextReading, on_delete=models.CASCADE,
                                     related_name='text_reading_answers')
