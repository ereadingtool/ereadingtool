from typing import TypeVar, Optional, Dict

from django.db import models
from django.utils import timezone
from django.utils.functional import cached_property
from statemachine import StateMachine, State

from mixins.model import Timestamped
from question.models import Question, Answer
from text.models import Text, TextSection
from text_reading.exceptions import (TextReadingInvalidState, TextReadingNotAllQuestionsAnswered,
                                     TextReadingQuestionNotInSection)
from user.student.models import Student


class TextReadingStateMachine(StateMachine):
    intro = State('intro', initial=True)
    in_progress = State('in_progress')
    complete = State('complete')

    reading = intro.to(in_progress)

    next = in_progress.to(in_progress)
    prev = in_progress.to(in_progress)

    back_to_intro = in_progress.to(intro)

    completing = in_progress.to(complete)

    back_to_reading = complete.to(in_progress)

    def next_state(self, next_section: Optional[TextSection]=None, reading=True, *args, **kwargs):
        if self.is_intro and next_section:
            self.reading()

        elif self.is_in_progress and next_section:
            self.next()

        elif self.is_in_progress and not next_section:
            self.completing()

    def prev_state(self, prev_section: Optional[TextSection]=None, reading=True, *args, **kwargs):
        if self.is_in_progress and prev_section:
            self.prev()

        elif self.is_in_progress and not prev_section:
            self.back_to_intro()

        elif self.is_complete:
            self.back_to_reading()


class TextReading(models.Model):
    """
    A model that keeps track of individual text reading sessions.
    """
    student = models.ForeignKey(Student, null=False, on_delete=models.CASCADE, related_name='text_readings')
    text = models.ForeignKey(Text, null=False, on_delete=models.CASCADE)

    state = models.CharField(max_length=64, null=False, default=TextReadingStateMachine.intro.name)

    currently_reading = models.NullBooleanField()
    current_section = models.ForeignKey(TextSection, null=True, on_delete=models.CASCADE, related_name='text_readings')

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True)

    def to_dict(self) -> Dict:
        return {
            'id': self.pk,
            'text': str(self.text),
            'current_section': str(self.current_section.order+1) if self.current_section else None,
            'status': self.state
        }

    def to_text_reading_dict(self) -> Dict:
        if self.state_machine.is_in_progress:
            return self.get_current_section().to_text_reading_dict(text_reading=self,
                                                                   num_of_sections=len(self.sections))

        elif self.state_machine.is_intro:
            return self.text.to_text_reading_dict()

        elif self.state_machine.is_complete:
            answered_correctly = self.text_reading_answers.order_by('-created_dt').filter(
                question=models.OuterRef('question'))

            scores = self.text_reading_answers.values('question').annotate(
                num_answered_question=models.Count('question'),
            ).annotate(answered_correctly=models.Subquery(answered_correctly.values('answer__correct')[:1]))

            question_scores = sum([1 if answer['answered_correctly'] else 0 for answer in scores])

            return {
                'num_of_sections': len(self.sections),
                'complete_sections': len(self.sections),
                'section_scores': question_scores,
                'possible_section_scores':
                    len(self.sections) * sum([section.questions.count() for section in self.sections])
            }

    @cached_property
    def sections(self):
        return self.text.sections.all()

    @property
    def current_state(self):
        return self.state_machine.current_state

    def get_current_section(self):
        if self.current_state != self.state_machine.in_progress:
            raise TextReadingInvalidState(code='invalid_state',
                                          error_msg=f"Can't access current section in state {self.current_state}")

        return self.current_section

    def set_end_dt(self):
        self.end_dt = timezone.now()
        self.save()

    def on_enter_complete(self, *args, **kwargs):
        self.set_end_dt()

    def began_reading_validator(self, *args, **kwargs):
        pass

    def next_validator(self, *args, **kwargs):
        current_section = self.get_current_section()

        if TextReadingAnswers.objects.filter(
                text_reading=self,
                text_section=current_section).count() < current_section.questions.count():
            raise TextReadingNotAllQuestionsAnswered(
                code='questions_unanswered',
                error_msg='Please answer all questions before continuing to the next section.'
            )

    def __init__(self, *args, **kwargs):
        """
        Deserialize the state from the db.
        """
        super(TextReading, self).__init__(*args, **kwargs)

        self.state_machine = TextReadingStateMachine()

        self.state_machine.reading.validators = [self.began_reading_validator]
        self.state_machine.next.validators = [self.next_validator]
        self.state_machine.on_enter_complete = self.on_enter_complete

        self.state_machine.current_state = getattr(TextReadingStateMachine, self.state)

    def answer(self, answer: Answer) -> Optional[TypeVar('TextReadingAnswers')]:
        if answer.question.text_section != self.current_section:
            raise TextReadingQuestionNotInSection(code='question_not_in_section',
                                                  error_msg='This question is not in this section.')

        if not TextReadingAnswers.objects.filter(text_reading=self,
                                                 text_section=self.current_section,
                                                 question=answer.question,
                                                 answer=answer).count():

            text_reading_answers = TextReadingAnswers(text_reading=self,
                                                      text_section=self.current_section,
                                                      question=answer.question,
                                                      answer=answer)

            text_reading_answers.save()

            return text_reading_answers

        return None

    def prev(self, *args, **kwargs):
        """

        :param args:
        :param kwargs:
        :return:
        """
        prev_section = None

        if self.state_machine.is_in_progress and self.current_section:
            try:
                i = self.current_section.order - 1

                if i > -1:
                    prev_section = self.sections[i]
            except IndexError:
                pass
        elif self.state_machine.is_complete:
            prev_section = self.sections[len(self.sections)-1]

        self.state_machine.prev_state(prev_section=prev_section, **kwargs)

        self.current_section = prev_section

        self.state = self.current_state.name

        self.save()

    def next(self, *args, **kwargs):
        """

        :param args:
        :param kwargs:
        :return:
        """
        next_section = None

        if self.current_section:
            try:
                next_section = self.sections[self.current_section.order + 1]
            except IndexError:
                pass

        elif self.state_machine.is_intro:
            next_section = self.sections[0]

        self.state_machine.next_state(next_section=next_section, **kwargs)

        self.current_section = next_section

        self.state = self.current_state.name

        self.save()

    @classmethod
    def start(cls, student: Student, text: Text) -> TypeVar('TextReading'):
        """

        :param student:
        :param text:
        :return: TextReading
        """
        text_reading = cls.objects.create(student=student, text=text)

        return text_reading

    @classmethod
    def resume(cls, student: Student, text: Text) -> TypeVar('TextReading'):
        """

        :param student:
        :param text:
        :return:
        """

        return cls.objects.filter(student=student, text=text).exclude(state=TextReadingStateMachine.complete.name).get()

    @classmethod
    def start_or_resume(cls, student: Student, text: Text) -> TypeVar('TextReading'):
        if cls.objects.filter(student=student, text=text).exclude(state=TextReadingStateMachine.complete.name).count():
            return False, cls.resume(student=student, text=text)
        else:
            return True, cls.start(student=student, text=text)


class TextReadingAnswers(Timestamped, models.Model):
    text_reading = models.ForeignKey(TextReading, on_delete=models.CASCADE, related_name='text_reading_answers')
    text_section = models.ForeignKey(TextSection, on_delete=models.CASCADE, related_name='text_reading_answers')

    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='text_reading_answers')
    answer = models.ForeignKey(Answer, on_delete=models.CASCADE, related_name='text_reading_answers')

    def __str__(self):
        return f'Text Reading {self.text_reading.pk} for section {self.text_section.pk} question {self.question.pk} ' \
               f'answer {self.answer.pk} (correct: {self.answer.correct})'

    class Meta:
        unique_together = (('text_reading', 'text_section', 'question', 'answer'),)
