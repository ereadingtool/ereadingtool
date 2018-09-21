from typing import TypeVar, Optional, Dict, Union

from django.db import models
from django.utils import timezone
from django.utils.functional import cached_property
from statemachine import StateMachine, State

from mixins.model import Timestamped
from question.models import Question, Answer
from text.models import Text, TextSection
from text_reading.exceptions import (TextReadingInvalidState, TextReadingNotAllQuestionsAnswered,
                                     TextReadingQuestionNotInSection)


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
    class Meta:
        abstract = True

    """
    A model that keeps track of individual text reading sessions.
    """
    state_machine_cls = TextReadingStateMachine

    text = models.ForeignKey(Text, null=False, on_delete=models.CASCADE)

    state = models.CharField(max_length=64, null=False, default=state_machine_cls.intro.name)

    currently_reading = models.NullBooleanField()
    current_section = models.ForeignKey(TextSection, null=True, on_delete=models.CASCADE)

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True)

    def __init__(self, *args, **kwargs):
        """
        Deserialize the state from the db.
        """
        super(TextReading, self).__init__(*args, **kwargs)

        self.state_machine = self.state_machine_cls()

        self.state_machine.next.validators = [self.next_validator]
        self.state_machine.on_enter_complete = self.on_enter_complete

        self.state_machine.current_state = getattr(self.state_machine_cls, self.state)

    def to_dict(self) -> Dict:
        return {
            'id': self.pk,
            'text_id': self.text.pk,
            'text': str(self.text),
            'current_section': str(self.current_section.order+1) if self.current_section else None,
            'status': self.state,
            'score': self.score
        }

    @property
    def text_reading_answer_cls(self) -> TypeVar('TextReadingAnswers', bound='TextReadingAnswers'):
        raise NotImplementedError

    @property
    def score(self) -> Dict:
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
            'possible_section_scores': len(self.sections) * len(scores)
        }

    def to_text_reading_dict(self) -> Dict:
        if self.state_machine.is_in_progress:
            return self.get_current_section().to_text_reading_dict(text_reading=self,
                                                                   num_of_sections=len(self.sections))

        elif self.state_machine.is_intro:
            return self.text.to_text_reading_dict()

        elif self.state_machine.is_complete:
            return self.score

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

    def next_validator(self, *args, **kwargs):
        current_section = self.get_current_section()

        if self.text_reading_answer_cls.objects.filter(
                text_reading=self,
                text_section=current_section).count() < current_section.questions.count():
            raise TextReadingNotAllQuestionsAnswered(
                code='questions_unanswered',
                error_msg='Please answer all questions before continuing to the next section.'
            )

    def answer(self, answer: Answer) -> Optional[TypeVar('TextReadingAnswers', bound='TextReadingAnswers')]:
        if answer.question.text_section != self.current_section:
            raise TextReadingQuestionNotInSection(code='question_not_in_section',
                                                  error_msg='This question is not in this section.')

        if not self.text_reading_answer_cls.objects.filter(text_reading=self,
                                                           text_section=self.current_section,
                                                           question=answer.question, answer=answer).count():

            text_reading_answers = self.text_reading_answer_cls(text_reading=self,
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
    def start(cls, profile: Union[TypeVar('Student'), TypeVar('Instructor')],
              text: Text) -> TypeVar('TextReadingAnswers', bound='TextReading'):
        raise NotImplementedError

    @classmethod
    def resume(cls, profile: Union[TypeVar('Student'), TypeVar('Instructor')],
               text: Text) -> TypeVar('TextReadingAnswers', bound='TextReading'):
        raise NotImplementedError

    @classmethod
    def start_or_resume(cls, profile: Union[TypeVar('Student'), TypeVar('Instructor')],
                        text: Text) -> TypeVar('TextReadingAnswers', bound='TextReading'):
        raise NotImplementedError


class TextReadingAnswers(Timestamped, models.Model):
    class Meta:
        abstract = True
        unique_together = (('text_reading', 'text_section', 'question', 'answer'),)

    text_reading = NotImplemented
    text_section = models.ForeignKey(TextSection, on_delete=models.CASCADE)

    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    answer = models.ForeignKey(Answer, on_delete=models.CASCADE)

    def __str__(self):
        return f'Text Reading {self.text_reading.pk} for section {self.text_section.pk} question {self.question.pk} ' \
               f'answer {self.answer.pk} (correct: {self.answer.correct})'
