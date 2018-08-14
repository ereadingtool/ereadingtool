from typing import TypeVar, Optional

from statemachine import StateMachine, State
from django.db import models
from django.utils.functional import cached_property

from text.models import Text, TextSection
from question.models import Question, Answer
from user.student.models import Student
from mixins.model import Timestamped


class TextReadingStateMachine(StateMachine):
    intro = State('intro', initial=True)
    in_progress = State('in_progress')
    complete = State('complete')

    reading = intro.to(in_progress)
    next = in_progress.to(in_progress)
    completing = in_progress.to(complete)

    def next_state(self, section: Optional[TextSection]=None, reading=True, *args, **kwargs):
        if self.current_state == self.intro and section:
            self.reading()

        elif self.current_state == self.in_progress and section:
            self.next()

        elif self.current_state == self.in_progress and not section:
            self.completing()

    def on_exit_complete(self, *args, **kwargs):
        pass


class TextReading(models.Model):
    """
    A model that keeps track of individual text reading sessions.
    """
    student = models.ForeignKey(Student, null=False, on_delete=models.CASCADE)
    text = models.ForeignKey(Text, null=False, on_delete=models.CASCADE)

    state = models.CharField(max_length=64, null=False, default=TextReadingStateMachine.intro.name)

    currently_reading = models.NullBooleanField()
    current_section = models.ForeignKey(TextSection, null=True, on_delete=models.CASCADE)

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True)

    @cached_property
    def sections(self):
        return self.text.sections.all()

    @property
    def current_state(self):
        return self.state_machine.current_state

    def began_reading_validator(self, *args, **kwargs):
        pass

    def next_validator(self, *args, **kwargs):
        pass

    def __init__(self, *args, **kwargs):
        """
        Deserialize the state from the db.
        """
        super(TextReading, self).__init__(*args, **kwargs)

        self.state_machine = TextReadingStateMachine()

        self.state_machine.reading.validators = [self.began_reading_validator]
        self.state_machine.next.validators = [self.next_validator]

        self.state_machine.current_state = getattr(TextReadingStateMachine, self.state)

    def next(self, *args, **kwargs):
        next_section = None

        if self.current_section:
            try:
                next_section = self.sections[self.current_section.order + 1]
            except IndexError:
                pass

        elif self.state_machine.current_state == self.state_machine.intro:
            next_section = self.sections[0]

        self.state_machine.next_state(section=next_section, **kwargs)

        self.current_section = next_section

        self.save()

    @classmethod
    def start(cls, student: Student, text: Text) -> TypeVar('TextReading'):
        text_reading = cls.objects.create(student=student, text=text)

        return text_reading


class TextSectionReading(Timestamped, models.Model):
    text_reading = models.ForeignKey(TextReading, on_delete=models.CASCADE, related_name='text_section_readings')
    text_section = models.ForeignKey(TextSection, on_delete=models.CASCADE, related_name='text_section_readings')

    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='text_section_readings')
    answer = models.ForeignKey(Answer, on_delete=models.CASCADE, related_name='text_section_readings')
