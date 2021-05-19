import json

from typing import TypeVar, Optional, Dict, Union

from django.db import models
from django.utils import timezone
from django.utils.functional import cached_property
from django.db.models import Count, Sum

from mixins.model import Timestamped
from question.models import Question, Answer
from text.models import Text, TextSection
from text_reading.state.models import TextReadingStateMachine
from text_reading.exceptions import (TextReadingInvalidState, TextReadingNotAllQuestionsAnswered,
                                     TextReadingQuestionNotInSection)

from dashboard.text_reader_sync import dashboard_synchronize_text_reading


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
    last_read_dt = models.DateTimeField(null=True)

    random_seed = models.CharField(max_length=256, null=False)

    def __init__(self, *args, **kwargs):
        """
        Deserialize the state from the db.
        """
        super(TextReading, self).__init__(*args, **kwargs)

        self.state_machine = self.state_machine_cls()

        self.state_machine.next.validators = [self.next_validator]
        self.state_machine.completing.validators = [self.next_validator]

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
    def text_reading_answer_cls(self) -> 'TextReadingAnswers':
        raise NotImplementedError

    @property
    def complete(self):
        return self.state == self.state_machine_cls.complete.name

    @property
    def in_progress(self):
        return self.state == self.state_machine_cls.in_progress.name

    @property
    def intro(self):
        return self.state == self.state_machine_cls.intro.name

    @property
    def score(self) -> Dict:
        answered_correctly = self.text_reading_answers.order_by('created_dt').filter(
            question=models.OuterRef('question'))

        scores = self.text_reading_answers.values('question').annotate(
            num_answered_question=models.Count('question'),
        ).annotate(
            answered_correctly=models.Subquery(answered_correctly.values('answer__correct')[:1])
        )

        question_scores = sum([1 if answer['answered_correctly'] else 0 for answer in scores])

        complete_sections = 0

        if self.in_progress:
            complete_sections = self.current_section.order
        elif self.complete:
            complete_sections = self.number_of_sections

        return {
            'num_of_sections': self.number_of_sections,
            'complete_sections': complete_sections,
            'section_scores': question_scores,
            'possible_section_scores': len(scores)
        }

    def to_text_reading_dict(self, **kwargs) -> Dict:
        if self.state_machine.is_in_progress:
            return self.get_current_section().to_text_reading_dict(text_reading=self,
                                                                   num_of_sections=self.number_of_sections)

        elif self.state_machine.is_intro:
            return self.text.to_text_reading_dict()

        elif self.state_machine.is_complete:
            return self.score

    @property
    def number_of_sections(self):
        return self.sections.count()

    @property
    def max_score(self):
        return self.sections.prefetch_related('questions').annotate(num_of_questions=Count('questions')).aggregate(
            max_score=Sum('num_of_questions'))['max_score']

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

    def set_last_read_dt(self):
        self.last_read_dt = timezone.now()
        self.save()

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

    def answer(self, answer: Answer) -> Optional['TextReadingAnswers']:
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
        self.refresh_from_db(fields=['state', 'current_section'])

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

        # Send the scores to Flagship connect
        if not next_section:
            dashboard_synchronize_text_reading(self)

        self.save()

    @classmethod
    def start(cls, profile: Union['Student', 'Instructor'], text: Text) -> 'TextReading':
        raise NotImplementedError

    @classmethod
    def resume(cls, profile: Union['Student', 'Instructor'], text: Text) -> 'TextReading':
        raise NotImplementedError

    @classmethod
    def start_or_resume(cls, profile: Union['Student', 'Instructor'], text: Text) -> 'TextReading':
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
