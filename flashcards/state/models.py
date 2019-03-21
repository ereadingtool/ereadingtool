from typing import TypeVar, Optional, AnyStr, Dict, List, Tuple

from enum import Enum, unique

from statemachine import StateMachine, State
from statemachine.exceptions import StateMachineError


class InvalidStateName(StateMachineError):
    pass


@unique
class Mode(Enum):
    review = """Review Only Mode.  This mode allows you to review your flashcards without submitting answers."""
    review_and_answer = """Review and Answer Mode.  This mode requires you to answer each flashcard as well as 
    self-assess your performance."""


class FlashcardSessionStateMachine(StateMachine):
    def __init__(self, *args, state: Optional[AnyStr] = None, mode: Optional[AnyStr] = None,
                 current_flashcard: Optional['Flashcard'] = None, **kwargs):
        super(FlashcardSessionStateMachine, self).__init__(*args, **kwargs)

        self.mode = getattr(self, mode, Mode.review)

        if state:
            if not hasattr(self.__class__, state):
                raise InvalidStateName()

            self.current_state = getattr(self.__class__, state)

        self.current_flashcard = current_flashcard

    mode_choice = State('mode_choice', initial=True)
    finished = State('finished')

    review_card = State('review_card')
    review_and_answer_card = State('review_answer_card')

    reviewed_card = State('reviewed_card')
    answered_card = State('answered_card')
    rated_your_answer_for_card = State('rate_your_answer_for_card')

    choose_mode = mode_choice.to.itself()

    start = mode_choice.to(review_and_answer_card) | mode_choice.to(review_card)

    answer_card = review_and_answer_card.to(answered_card)
    rate_answer = answered_card.to(rated_your_answer_for_card)

    review = review_card.to(reviewed_card)

    next_card = reviewed_card.to(review_card) | rated_your_answer_for_card.to(review_and_answer_card)

    finish = reviewed_card.to(finished) | rated_your_answer_for_card.to(finished)

    def set_mode_from_string(self, mode: AnyStr):
        try:
            i = [mode.name for mode in list(Mode)].index(mode)

            self.mode = list(Mode)[i]
        except ValueError:
            pass

        self.choose_mode()

    def serialize_mode_choice_state(self) -> List[Dict]:
        return [{'mode': mode.name, 'desc': mode.value, 'selected': self.mode == mode} for mode in list(Mode)]

    def serialize(self):
        return getattr(self, '_'.join(['serialize', self.current_state.name, 'state']))()
