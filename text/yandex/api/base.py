import json
import random

import requests
from django.utils import timezone

from text.yandex.exceptions import *


class YandexAPI(object):
    api_key = NotImplementedError
    last_request = NotImplementedError
    resp_to_exception = NotImplementedError

    def __init__(self, from_lang: AnyStr = 'ru', to_lang: AnyStr = 'en', **kwargs):
        self.from_lang = from_lang
        self.to_lang = to_lang

        self.last_request = None

        if not self.api_key:
            raise YandexInvalidAPIKeyException(message='The key for this API is missing.')

    def build_uri(self, uri: AnyStr, method: AnyStr, params: Dict) -> AnyStr:
        params['key'] = self.api_key
        params['lang'] = '-'.join([self.from_lang, self.to_lang])

        req_params = '&'.join(['='.join([k, v]) for k, v in params.items()])

        req = ''.join([uri, method, '?' + req_params])

        return req

    def request(self, uri: AnyStr, method: AnyStr, params: Dict) -> Dict:
        if self.last_request:
            while True:
                time_diff = timezone.now() - self.last_request

                if time_diff.total_seconds() >= random.randint(5, 10):
                    break

        req_str = self.build_uri(uri=uri, method=method, params=params)

        resp = requests.get(req_str)

        self.last_request = timezone.now()

        if resp.status_code != 200:
            raise self.resp_to_exception(resp)

        resp_json = json.loads(resp.text)

        return resp_json
