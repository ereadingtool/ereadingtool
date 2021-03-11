from typing import AnyStr


class TextReadingException(Exception):
    def __init__(self, code: AnyStr, error_msg: AnyStr, *args, **kwargs):
        super(TextReadingException, self).__init__(*args, **kwargs)

        self.code = code
        self.error_msg = error_msg

    def __repr__(self):
        return self.error_msg


class TextReadingInvalidState(TextReadingException):
    pass


class TextReadingQuestionNotInSection(TextReadingException):
    pass


class TextReadingQuestionAlreadyAnswered(TextReadingException):
    pass


class TextReadingNotAllQuestionsAnswered(TextReadingException):
    pass