import requests
import json

from django.conf import settings

from text.yandex.api.base import YandexAPI

from text.yandex.exceptions import *


class YandexPhrase(object):
    def __init__(self, text: AnyStr, language: AnyStr, *args, **kwargs):
        self.text = text
        self.language = language

    @property
    def is_english(self):
        return self.language == 'en'


class YandexExamples(object):
    def __len__(self):
        return len(self.examples)

    def __getitem__(self, item):
        return self.examples[item]

    def __iter__(self):
        for example in self.examples:
            yield example

    def __init__(self, phrase: AnyStr, language: AnyStr, examples: List[Dict], *args, **kwargs):
        self.phrase = phrase
        self.language = language
        self.examples = list()

        for ex in examples:
            try:
                example_text = ex['tr'][0]['text']
            except (KeyError, IndexError):
                example_text = None

            self.examples.append(YandexExample(text=ex['text'], example=example_text))


class YandexTranslation(object):
    def __init__(self, phrase: AnyStr, language: AnyStr, examples: YandexExamples, **kwargs):
        self.phrase = phrase
        self.language = language
        self.examples = examples


class YandexTranslations(object):
    def __len__(self):
        return len(self.translations)

    def __getitem__(self, item):
        return self.translations[item]

    def __iter__(self):
        for translation in self.translations:
            yield translation

    def __init__(self, phrase: AnyStr, language: AnyStr, translations: List[Dict], **kwargs):
        self.phrase = phrase
        self.language = language
        self.translations = list()

        for tr in translations:
            tr_text = tr.pop('text')

            tr_params = {
                'phrase': YandexPhrase(text=tr_text, language=language, grammemes=tr),
                'language': language,
                'examples': None
            }

            if 'ex' in tr:
                tr_params['examples'] = YandexExamples(phrase=tr_text,
                                                       language=language,
                                                       examples=tr['ex'])

            self.translations.append(YandexTranslation(**tr_params))


class YandexExample(object):
    def __init__(self, text: AnyStr, example: AnyStr, *args, **kwargs):
        self.text = text
        self.example_translation = example


class YandexDefinition(object):
    def __init__(self, phrase: Union[YandexPhrase, None], translations: YandexTranslations, *args, **kwargs):
        self.phrase = phrase
        self.translations = translations


class YandexDefinitions(object):
    def __len__(self):
        return len(self.definitions)

    def __getitem__(self, item):
        return self.definitions[item]

    def __iter__(self):
        for definition in self.definitions:
            yield definition

    def __init__(self, from_lang: AnyStr, to_lang: AnyStr, phrase: AnyStr, definitions: List[Dict], **kwargs):
        self.from_lang = from_lang
        self.to_lang = to_lang

        self.phrase = phrase

        self.definitions = list()

        for definition in definitions:
            definition_text = definition.pop('text')

            definition_params = {
                'phrase': phrase,
                'language': self.to_lang,
                'grammemes': definition
            }

            if 'tr' in definition:
                definition_params['translations'] = YandexTranslations(phrase=phrase,
                                                                       language=self.to_lang,
                                                                       translations=definition['tr'])

            yandex_definition = YandexDefinition(**definition_params)

            self.definitions.append(yandex_definition)


class YandexDefinitionAPI(YandexAPI):
    api_key = settings.YANDEX_DEFINITION_API_KEY
    yandex_definition_uri = 'https://dictionary.yandex.net/api/v1/dicservice.json/'

    def resp_to_exception(self, resp: requests.Response) -> YandexException:
        resp_json = json.loads(resp.content)

        status_code = resp_json['code']

        exceptions = {
            401: YandexInvalidAPIKeyException(message='Invalid API key'),
            402: YandexBlockedAPIKeyException(message='Blocked API key'),
            403: YandexExceededDailyLimitException(
                message='Exceeded the daily limit on the amount of translated text'),
            413: YandexMaxTextSizeException(message='Exceeded the maximum text size'),
            501: YandexLangNotSupportedException(message='The specified translation direction is not supported')
        }

        return exceptions.get(status_code, YandexException(message=resp.reason))

    def lookup(self, phrase: AnyStr) -> Union[YandexDefinitions, None]:
        definitions = None

        resp = self.request(uri=self.yandex_definition_uri, method='lookup', params={
            'text': phrase
        })

        if 'def' in resp:
            definitions = YandexDefinitions(
                from_lang=self.from_lang,
                to_lang=self.to_lang,
                phrase=phrase,
                definitions=resp['def']
            )

        return definitions
