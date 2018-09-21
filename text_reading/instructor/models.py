from typing import TypeVar

from django.db import models

from text.models import Text

from text_reading.models import TextReading, TextReadingAnswers
from user.instructor.models import Instructor


class InstructorTextReading(TextReading):
    instructor = models.ForeignKey(Instructor, null=False, on_delete=models.CASCADE, related_name='text_readings')

    @classmethod
    def start(cls, instructor: Instructor, text: Text) -> TypeVar('InstructorTextReading'):
        """

        :param instructor:
        :param text:
        :return: TextReading
        """
        text_reading = cls.objects.create(instructor=instructor, text=text)

        return text_reading

    @classmethod
    def resume(cls, instructor: Instructor, text: Text) -> TypeVar('InstructorTextReading'):
        """

        :param instructor:
        :param text:
        :return: TextReading
        """

        return cls.objects.filter(instructor=instructor,
                                  text=text).exclude(state=cls.state_machine_cls.complete.name).get()

    @classmethod
    def start_or_resume(cls, instructor: Instructor, text: Text) -> TypeVar('InstructorTextReading'):
        """

        :param instructor:
        :param text:
        :return: TextReading
        """

        if cls.objects.filter(instructor=instructor,
                              text=text).exclude(state=cls.state_machine_cls.complete.name).count():
            return False, cls.resume(instructor=instructor, text=text)
        else:
            return True, cls.start(instructor=instructor, text=text)


class InstructorTextReadingAnswers(TextReadingAnswers):
    text_reading = models.ForeignKey(InstructorTextReading, on_delete=models.CASCADE,
                                     related_name='text_reading_answers')
