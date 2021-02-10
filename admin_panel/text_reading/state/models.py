from typing import TypeVar, Optional

from statemachine import StateMachine, State

TextSection = TypeVar('TextSection')


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

    def next_state(self, next_section: Optional[TextSection] = None, reading=True, *args, **kwargs):
        if self.is_intro and next_section:
            self.reading()

        elif self.is_in_progress and next_section:
            self.next()

        elif self.is_in_progress and not next_section:
            self.completing()

    def prev_state(self, prev_section: Optional[TextSection] = None, reading=True, *args, **kwargs):
        if self.is_in_progress and prev_section:
            self.prev()

        elif self.is_in_progress and not prev_section:
            self.back_to_intro()

        elif self.is_complete:
            self.back_to_reading()
