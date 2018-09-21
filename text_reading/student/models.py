from typing import TypeVar

from django.db import models

from text.models import Text

from text_reading.models import TextReading, TextReadingAnswers
from user.student.models import Student


class StudentTextReading(TextReading):
    student = models.ForeignKey(Student, null=False, on_delete=models.CASCADE, related_name='text_readings')

    @classmethod
    def start(cls, student: Student, text: Text) -> TypeVar('StudentTextReading'):
        """

        :param student:
        :param text:
        :return: TextReading
        """
        text_reading = cls.objects.create(student=student, text=text)

        return text_reading

    @classmethod
    def resume(cls, student: Student, text: Text) -> TypeVar('StudentTextReading'):
        """

        :param student:
        :param text:
        :return: TextReading
        """
        return cls.objects.filter(student=student,
                                  text=text).exclude(state=cls.state_machine_cls.complete.name).get()

    @classmethod
    def start_or_resume(cls, student: Student, text: Text) -> TypeVar('StudentTextReading'):
        """

        :param student:
        :param text:
        :return: TextReading
        """
        if cls.objects.filter(student=student,
                              text=text).exclude(state=cls.state_machine_cls.complete.name).count():
            return False, cls.resume(student=student, text=text)
        else:
            return True, cls.start(student=student, text=text)


class StudentTextReadingAnswers(TextReadingAnswers):
    text_reading = models.ForeignKey(StudentTextReading, on_delete=models.CASCADE,
                                     related_name='text_reading_answers')
