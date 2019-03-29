import math

from typing import TypeVar, Optional, AnyStr, Dict, List, Tuple, Union

from enum import Enum, unique

from django.db import models

from django.utils import timezone
from django.db.utils import cached_property

from django.db import DatabaseError, transaction

from statemachine import StateMachine, State
from statemachine.exceptions import TransitionNotAllowed
from flashcards.state.exceptions import (InvalidStateName, FlashcardStateMachineException,
                                         FlashcardStateMachineNoDefFoundException)

from text.phrase.models import TextPhrase


@unique
class Mode(Enum):
    review = """Review Only Mode.  This mode allows you to review your flashcards without submitting answers."""
    review_and_answer = """Review and Answer Mode.  This mode requires you to answer each flashcard as well as 
    self-assess your performance."""


class FlashcardSessionStateMachine(StateMachine):
    def __init__(self, *args, flashcards_queryset: models.QuerySet, state: Optional[AnyStr] = None,
                 mode: Optional[AnyStr] = None, current_flashcard: Optional['Flashcard'], **kwargs):
        super(FlashcardSessionStateMachine, self).__init__(*args, **kwargs)

        if mode:
            self.mode = getattr(Mode, mode, Mode.review)

        if state:
            if not hasattr(self.__class__, state):
                raise InvalidStateName()

            self.current_state = getattr(self.__class__, state)

        self.flashcards = flashcards_queryset

        if not current_flashcard:
            try:
                self.current_flashcard = self.next_flashcard
            except IndexError:
                pass

        self.current_flashcard = current_flashcard

    mode_choice = State('mode_choice', initial=True)

    finished_review = State('finished_review')
    finished_review_and_answer = State('finished_review')

    review_card = State('review_card')
    review_and_answer_card = State('review_and_answer_card')

    reviewed_card = State('reviewed_card')

    correctly_answered_card = State('correctly_answered_card')
    incorrectly_answered_card = State('incorrectly_answered_card')

    rated_your_answer_for_card = State('rated_your_answer_for_card')

    choose_mode = mode_choice.to.itself()

    # internal transitions used by start()
    _start_review = mode_choice.to(review_card)
    _start_review_and_answer = mode_choice.to(review_and_answer_card)

    rate_answer = correctly_answered_card.to(rated_your_answer_for_card)

    # internal transitions used by answer_card()
    _answered_card_correctly = review_and_answer_card.to(correctly_answered_card)
    _answered_card_incorrectly = review_and_answer_card.to(incorrectly_answered_card)

    review = review_card.to(reviewed_card)

    next_card = reviewed_card.to(
        review_card
    ) | rated_your_answer_for_card.to(
        review_and_answer_card
    ) | incorrectly_answered_card.to(
        review_and_answer_card
    )

    prev_card = reviewed_card.to(
        review_card
    ) | rated_your_answer_for_card.to(
        review_and_answer_card
    ) | incorrectly_answered_card.to(
        review_and_answer_card
    )

    back_to_mode_choice = reviewed_card.to(
        mode_choice
    ) | rated_your_answer_for_card.to(
        mode_choice
    ) | incorrectly_answered_card.to(
        mode_choice
    )

    finish = reviewed_card.to(
        finished_review
    ) | rated_your_answer_for_card.to(
        finished_review_and_answer
    ) | incorrectly_answered_card.to(
        finished_review_and_answer
    )

    def start(self):
        mode_to_start_transition = {
            Mode.review.name: self._start_review,
            Mode.review_and_answer.name: self._start_review_and_answer
        }

        try:
            mode_to_start_transition[self.mode.name]()
        except KeyError:
            raise FlashcardStateMachineException(code='invalid_mode',
                                                 error_msg=f'Mode {self.mode.name} does not have a start transition.')

    @property
    def prev_review_only_flashcard(self):
        if not self.current_flashcard:
            try:
                return self.flashcards.filter(created_dt__lt=self.current_flashcard.created_dt)[-1]
            except IndexError:
                return None

        try:
            return self.flashcards.filter(created_dt__lt=self.current_flashcard.created_dt)[0]
        except IndexError:
            return None

    @property
    def next_review_only_flashcard(self):
        if not self.current_flashcard:
            self.current_flashcard = self.flashcards[0]

            return self.current_flashcard

        try:
            return self.flashcards.filter(created_dt__gt=self.current_flashcard.created_dt)[0]
        except IndexError:
            return None

    @property
    def next_review_and_answer_flashcard(self):
        try:
            return self.flashcards.filter(next_review_dt__lt=timezone.now()).order_by('repetitions',
                                                                                      'next_review_dt')[0]
        except IndexError:
            return None

    @property
    def prev_flashcard(self):
        if self.mode == self.mode.review:
            return self.prev_review_only_flashcard
        else:
            # no previous flashcard in review and answer mode
            return None

    @property
    def next_flashcard(self):
        if self.mode == self.mode.review:
            return self.next_review_only_flashcard
        else:
            return self.next_review_and_answer_flashcard

    def prev(self):
        prev_flashcard = self.prev_flashcard

        try:
            if prev_flashcard:
                self.prev_card()
                self.current_flashcard = prev_flashcard
            else:
                self.back_to_mode_choice()

        except TransitionNotAllowed as transition_exception:
            raise FlashcardStateMachineException(code=transition_exception.transition.identifier,
                                                 error_msg=str(transition_exception))

    def next(self):
        next_flashcard = self.next_flashcard

        if next_flashcard:
            try:
                self.next_card()

            except TransitionNotAllowed as transition_exception:
                if self.current_state == self.correctly_answered_card:
                    raise FlashcardStateMachineException(code=transition_exception.transition.identifier,
                                                         error_msg='Rate your answer before continuing.')

                elif self.current_state in [self.review_and_answer_card, self.review_card]:
                    raise FlashcardStateMachineException(
                        code=transition_exception.transition.identifier,
                        error_msg='Must review or answer this card before continuing.')

                raise FlashcardStateMachineException(code=transition_exception.transition.identifier,
                                                     error_msg=str(transition_exception))

            self.current_flashcard = next_flashcard
        else:
            try:
                self.finish()

            except TransitionNotAllowed as transition_exception:
                raise FlashcardStateMachineException(code=transition_exception.transition.identifier,
                                                     error_msg=str(transition_exception))

    @property
    def translation_for_current_flashcard(self) -> Union[TextPhrase, None]:
        try:
            return self.current_flashcard.phrase.translations.filter(correct_for_context=True)[0]
        except IndexError:
            return None

    def rate_quality(self, rating: int):
        # SM-2
        if rating in range(0, 6):
            card = self.current_flashcard

            card.easiness = max(1.3, card.easiness + 0.1 - (5.0 - rating) * (0.08 + (5.0 - rating) * 0.02))

            if rating < 3:
                card.repetitions = 0
            else:
                card.repetitions += 1

            if card.repetitions == 1:
                card.interval = 1
            elif card.repetitions == 2:
                card.interval = 6
            else:
                card.interval *= card.easiness

            card.next_review_dt = (timezone.now().replace(second=0, microsecond=0) +
                                   timezone.timedelta(days=math.ceil(card.interval)))

            self.current_flashcard = card

            try:
                self.current_flashcard.save()
                self.rate_answer()
            except DatabaseError:
                pass

    def answer_card(self, answer: AnyStr):
        if self.translation_for_current_flashcard.phrase == answer:
            self._answered_card_correctly()
        else:
            self._answered_card_incorrectly()

    def set_mode_from_string(self, mode: AnyStr):
        try:
            i = [mode.name for mode in list(Mode)].index(mode)

            self.mode = list(Mode)[i]
        except ValueError:
            pass

        self.choose_mode()

    def serialize_rated_your_answer_for_card_state(self) -> Dict:
        return self.serialize_reviewed_card_state()

    def serialize_finished_review_state(self) -> Dict:
        return {}

    def serialize_finished_review_and_answer_state(self) -> Dict:
        return {}

    def serialize_reviewed_card_state(self) -> Dict:
        flashcard_dict = self.serialize_review_card_state()

        flashcard_dict['translation'] = self.translation_for_current_flashcard.phrase

        return flashcard_dict

    def serialize_mode_choice_state(self) -> List[Dict]:
        return [{'mode': mode.name, 'desc': mode.value, 'selected': self.mode == mode} for mode in list(Mode)]

    def serialize_review_card_state(self) -> Dict:
        flashcard_dict = self.current_flashcard.to_dict()

        if 'student' in flashcard_dict:
            del flashcard_dict['student']

        flashcard_dict['translation'] = None

        return flashcard_dict

    def serialize_review_and_answer_card_state(self) -> Dict:
        return self.serialize_review_card_state()

    def serialize_correctly_answered_card_state(self) -> Dict:
        return self.serialize_reviewed_card_state()

    def serialize_incorrectly_answered_card_state(self) -> Dict:
        return self.serialize_reviewed_card_state()

    def serialize(self):
        return getattr(self, '_'.join(['serialize', self.current_state.name, 'state']))()
