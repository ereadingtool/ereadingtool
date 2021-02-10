from typing import AnyStr, Union, Dict, List


class YandexException(Exception):
    def __init__(self, message: AnyStr, *args, **kwargs):
        self.message = message

    def __str__(self):
        return f'{self.message}'


class YandexThrottlingException(YandexException):
    pass


class YandexInvalidAPIKeyException(YandexException):
    pass


class YandexBlockedAPIKeyException(YandexException):
    pass


class YandexExceededDailyLimitException(YandexException):
    pass


class YandexMaxTextSizeException(YandexException):
    pass


class YandexTextCannotBeTranslatedException(YandexException):
    pass


class YandexDirectionNotSupportedException(YandexException):
    pass


class YandexLangNotSupportedException(YandexException):
    pass
