from typing import AnyStr, Union, Dict, List

import requests
import json


class GlosbeDefinition(object):
    def __init__(self, phrase: AnyStr, definition: Dict, *args, **kwargs):
        self._phrase = phrase
        self.definition = definition

    @property
    def phrase(self) -> AnyStr:
        try:
            return self.definition['phrase']['text']
        except KeyError:
            return self._phrase

    @property
    def meanings(self) -> Union[List[Dict], None]:
        try:
            return self.definition['meanings']
        except KeyError:
            return None


class GlosbeDefinitions(object):
    def __init__(self, from_lang: AnyStr, to_lang: AnyStr, phrase: AnyStr, authors: Dict, definitions: List[Dict],
                 **kwargs):
        self.from_lang = from_lang
        self.to_long = to_lang

        self.phrase = phrase
        self.authors = authors

        self.definitions = dict()

        for d in definitions:
            definition = GlosbeDefinition(phrase=self.phrase, definition=d)

            self.definitions[definition.phrase] = definition


class GlosbeAPI(object):
    glosbe_domain = 'https://glosbe.com/gapi'

    def __init__(self, from_lang: AnyStr='ru', to_lang: AnyStr='en', tm: Union[bool, None]=None, **kwargs):
        self.from_lang = from_lang
        self.to_lang = to_lang

        self.tm = tm

    def translate(self, phrase: AnyStr) -> Union[GlosbeDefinitions, None]:
        definitions = None

        req_params = '&'.join([
            '='.join(['from', self.from_lang]),
            '='.join(['dest', self.to_lang]),
            '='.join(['phrase', phrase]),
            '='.join(['format', 'json'])
        ])

        req = '/'.join([self.glosbe_domain, 'translate', '?' + req_params])

        resp = json.loads(requests.get(req).text)

        tuc = resp['tuc']

        if 'result' in resp and resp['result'] == 'ok':
            definitions = GlosbeDefinitions(
                from_lang=resp.get('from'),
                to_lang=resp['dest'],
                phrase=resp['phrase'],
                authors=resp['authors'],
                definitions=tuc
            )

        return definitions
