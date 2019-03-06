from typing import AnyStr, Union, Dict, List

import random
import requests
import json

from django.utils import timezone


class GlosbeException(Exception):
    def __init__(self, message: AnyStr, *args, **kwargs):
        self.message = message

    def __str__(self):
        return f'{self.message}'


class GlosbeThrottlingException(GlosbeException):
    pass


class GlosbePhrase(object):
    def __init__(self, text: AnyStr, language: AnyStr):
        self.text = text
        self.language = language

    @property
    def is_english(self):
        return self.language == 'en'


class GlosbeTranslation(object):
    def __init__(self, phrase: Union[GlosbePhrase, None], translation: Dict, *args, **kwargs):
        self.phrase = phrase
        self.translation = translation

    @property
    def meanings(self) -> Union[List[Dict], None]:
        try:
            return self.translation['meanings']
        except KeyError:
            return None


class GlosbeTranslations(object):
    def __init__(self, from_lang: AnyStr, to_lang: AnyStr, phrase: AnyStr, authors: Dict, translations: List[Dict],
                 **kwargs):
        self.from_lang = from_lang
        self.to_long = to_lang

        self.phrase = phrase
        self.authors = authors

        self.translations = list()

        for d in translations:
            glosbe_phrase = None

            if 'phrase' in d:
                glosbe_phrase = GlosbePhrase(text=d['phrase']['text'], language=d['phrase']['language'])

            translation = GlosbeTranslation(
                phrase=glosbe_phrase,
                translation=d
            )

            self.translations.append(translation)


class GlosbeAPI(object):
    glosbe_domain = 'https://glosbe.com/gapi'

    def __init__(self, from_lang: AnyStr='ru', to_lang: AnyStr='en', tm: Union[bool, None]=None, **kwargs):
        self.from_lang = from_lang
        self.to_lang = to_lang

        self.tm = tm
        self.last_request = None

    def translate(self, phrase: AnyStr) -> Union[GlosbeTranslations, None]:
        definitions = None

        req_params = '&'.join([
            '='.join(['from', self.from_lang]),
            '='.join(['dest', self.to_lang]),
            '='.join(['phrase', phrase]),
            '='.join(['format', 'json'])
        ])

        req = '/'.join([self.glosbe_domain, 'translate', '?' + req_params])

        if self.last_request:
            while True:
                time_diff = timezone.now() - self.last_request

                if time_diff.total_seconds() >= random.randint(5, 10):
                    break

        resp = requests.get(req)

        if resp.status_code != 200:
            raise GlosbeException(message=resp.reason)

        resp = json.loads(requests.get(req).text)

        self.last_request = timezone.now()

        if resp['result'] == 'error':
            if resp['message'] == 'Too many queries, your IP has been blocked':
                raise GlosbeThrottlingException(message=resp['message'])
            else:
                raise GlosbeException(message=resp['message'])

        tuc = resp['tuc']

        if 'result' in resp and resp['result'] == 'ok':
            definitions = GlosbeTranslations(
                from_lang=resp.get('from'),
                to_lang=resp['dest'],
                phrase=resp['phrase'],
                authors=resp['authors'],
                translations=tuc
            )

        return definitions
