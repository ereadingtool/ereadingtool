import requests
import json

from django.conf import settings

from text.yandex.api.base import YandexAPI
from text.yandex.exceptions import *


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


class YandexTranslationAPI(YandexAPI):
    api_key = settings.YANDEX_TRANSLATION_API_KEY
    yandex_translate_uri = 'https://translate.yandex.net/api/v1.5/tr.json/'

    def resp_to_exception(self, resp: requests.Response) -> YandexException:
        resp_json = json.loads(resp.content)

        status_code = resp_json['code']

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
        super(YandexTranslationAPI, self).__init__(from_lang, to_lang, **kwargs)

        self.from_lang = from_lang
        self.to_lang = to_lang

        self.last_request = None

    def translate(self, phrase: AnyStr) -> Union[YandexTranslations, None]:
        translations = None

        resp = self.request(uri=self.yandex_translate_uri, method='translate', params={
            'text': phrase,
            'format': 'plain'
        })

        if 'text' in resp:
            translations = YandexTranslations(
                from_lang=self.from_lang,
                to_lang=self.to_lang,
                phrase=phrase,
                translations=resp['text']
            )

        return translations
