from typing import AnyStr
from statemachine.exceptions import StateMachineError


class InvalidStateName(StateMachineError):
    pass


class FlashcardStateMachineException(Exception):
    def __init__(self, code: AnyStr, error_msg: AnyStr, *args, **kwargs):
        super(FlashcardStateMachineException, self).__init__(*args)

        self.code = code
        self.error_msg = error_msg

    def __repr__(self):
        return self.error_msg


class FlashcardStateMachineNoDefFoundException(FlashcardStateMachineException):
    pass
