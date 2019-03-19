from typing import TypeVar, Optional, AnyStr

from enum import Enum, unique

from statemachine import StateMachine, State
from statemachine.exceptions import StateMachineError

from flashcards.models import Flashcard


@unique
class Mode(Enum):
    review = 'Review'
    review_and_answer = 'Review and Answer'


class FlashcardSessionStateMachine(StateMachine):
    def __init__(self, *args, state: Optional[AnyStr] = None, mode: Optional[AnyStr] = None,
                 current_flashcard: Optional[Flashcard] = None, **kwargs):
        super(FlashcardSessionStateMachine, self).__init__(*args, **kwargs)

        self.mode = getattr(self, mode, Mode.review)

        if state:
            self.current_state = getattr(self, state)

        self.current_flashcard = current_flashcard

    begin = State('mode_choice', initial=True)
    finished = State('finished')

    review_card = State('review_card')
    review_and_answer_card = State('review_answer_card')

    reviewed_card = State('reviewed_card')
    answered_card = State('answered_card')
    rated_your_answer_for_card = State('rate_your_answer_for_card')

    choose_mode = begin.to.itself()

    start = begin.to(review_and_answer_card) | begin.to(review_card)

    answer_card = review_and_answer_card.to(answered_card)
    rate_answer = answered_card.to(rated_your_answer_for_card)

    review = review_card.to(reviewed_card)

    next_card = reviewed_card.to(review_card) | rated_your_answer_for_card.to(review_and_answer_card)

    finish = reviewed_card.to(finished) | rated_your_answer_for_card.to(finished)
