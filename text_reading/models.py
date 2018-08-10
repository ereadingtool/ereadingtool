from typing import TypeVar

from statemachine import StateMachine, State
from django.db import models
from django.utils.functional import cached_property

from text.models import Text, TextSection
from user.student.models import Student


class TextReadingInProgress(object):
    def __init__(self, section: TextSection, reading: bool, **kwargs):
        """
        A value object for the in_progress state of TextReading.
        """
        self.section = section
        self.reading = reading


class TextReadingStateMachine(StateMachine):
    intro = State('intro', initial=True)
    in_progress = State('in_progress')
    complete = State('complete')

    reading = intro.to(in_progress)
    completing = in_progress.to(complete)


class TextReading(models.Model):
    """
    A model that keeps track of individual text reading sessions.
    """
    student = models.ForeignKey(Student, null=False, on_delete=models.CASCADE)
    text = models.ForeignKey(Text, null=False, on_delete=models.CASCADE)

    state = models.CharField(max_length=64, null=False, default=TextReadingStateMachine.intro.name)

    # if in_progress then:
    currently_reading = models.NullBooleanField()
    current_section = models.ForeignKey(TextSection, null=True, on_delete=models.CASCADE)

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True)

    class Meta:
        unique_together = (('student', 'text'),)

    @cached_property
    def sections(self):
        return self.text.sections.all()

    def __init__(self, *args, **kwargs):
        super(TextReading, self).__init__(*args, **kwargs)

        self.state_machine = TextReadingStateMachine()

    def reading(self):
        self.state_machine.reading()

        self.currently_reading = True
        self.current_section = self.sections[0]

        self.state_machine.current_state.value = TextReadingInProgress(section=self.current_section,
                                                                       reading=self.currently_reading)

        self.save()

    @classmethod
    def start(cls, student: Student, text: Text) -> TypeVar('TextReading'):
        text_reading = cls.objects.create(student=student, text=text)

        return text_reading
