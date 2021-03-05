from typing import AnyStr


class FlashcardSessionException(Exception):
    def __init__(self, code: AnyStr, error_msg: AnyStr, *args, **kwargs):
        super(FlashcardSessionException, self).__init__(*args, **kwargs)

        self.code = code
        self.error_msg = error_msg

    def __repr__(self):
        return self.error_msg
