from typing import AnyStr, Union, Dict, List

import random
import requests
import json

from django.utils import timezone

from django.conf import settings


class YandexException(Exception):
    def __init__(self, message: AnyStr, *args, **kwargs):
        self.message = message

    def __str__(self):
        return f'{self.message}'


class YandexThrottlingException(YandexException):
    pass


class YandexPhrase(object):
    def __init__(self, text: AnyStr, language: AnyStr):
        self.text = text
        self.language = language

    @property
    def is_english(self):
        return self.language == 'en'


class YandexTranslation(object):
    def __init__(self, phrase: Union[YandexPhrase, None], translation: Dict, *args, **kwargs):
        self.phrase = phrase
        self.translation = translation

    @property
    def meanings(self) -> Union[List[Dict], None]:
        try:
            return self.translation['meanings']
        except KeyError:
            return None


class YandexTranslations(object):
    def __init__(self, from_lang: AnyStr, to_lang: AnyStr, phrase: AnyStr, translations: List[Dict], **kwargs):
        self.from_lang = from_lang
        self.to_lang = to_lang

        self.phrase = phrase

        self.translations = list()

        for translated_phrase in translations:
            yandex_phrase = YandexPhrase(text=self.phrase, language=self.to_lang)

            translation = YandexTranslation(
                phrase=yandex_phrase,
                translation=translated_phrase
            )

            self.translations.append(translation)


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


class YandexTranslationAPI(object):
    yandex_translate_uri = 'https://translate.yandex.net/api/v1.5/tr.json/'

    def resp_to_exception(self, resp: requests.Response) -> YandexException:
        status_code = resp.status_code

        exceptions = {
            401: YandexInvalidAPIKeyException(message='Invalid API key'),
            402: YandexBlockedAPIKeyException(message='Blocked API key'),
            404: YandexExceededDailyLimitException(
                message='Exceeded the daily limit on the amount of translated text'),
            413: YandexMaxTextSizeException(message='Exceeded the maximum text size'),
            422: YandexTextCannotBeTranslatedException(message='The text cannot be translated'),
            501: YandexDirectionNotSupportedException(message='The specified translation direction is not supported')
        }

        return exceptions.get(status_code, YandexException(message=resp.reason))

    def __init__(self, from_lang: AnyStr = 'ru', to_lang: AnyStr = 'en', **kwargs):
        self.from_lang = from_lang
        self.to_lang = to_lang

        self.last_request = None

    def translate(self, phrase: AnyStr) -> Union[YandexTranslations, None]:
        definitions = None

        req_params = '&'.join([
            '='.join(['key', settings.YANDEX_TRANSLATION_API_KEY]),
            '='.join(['text', phrase]),
            '='.join(['lang', '-'.join([self.from_lang, self.to_lang])]),
            '='.join(['format', 'plain'])
        ])

        req = ''.join([self.yandex_translate_uri, 'translate', '?' + req_params])

        if self.last_request:
            while True:
                time_diff = timezone.now() - self.last_request

                if time_diff.total_seconds() >= random.randint(5, 10):
                    break

        resp = requests.get(req)

        if resp.status_code != 200:
            raise self.resp_to_exception(resp)

        resp = json.loads(requests.get(req).text)

        self.last_request = timezone.now()

        if 'text' in resp:
            definitions = YandexTranslations(
                from_lang=self.from_lang,
                to_lang=self.to_lang,
                phrase=phrase,
                translations=resp['text']
            )

        return definitions
