import json

import jsonschema

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from django.db import DatabaseError

from django.db import transaction

from text.translations.models import TextWord, TextWordTranslation


class TextWordAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['post']

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_word = None

        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text_word_add_translation_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_word_add_translation_params, TextWordTranslation.to_add_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_word = TextWord.objects.get(pk=kwargs['pk'])

            text_word_add_translation_params['word'] = text_word

            text_word_translation = TextWordTranslation.create(**text_word_add_translation_params)

            return HttpResponse(json.dumps({
                'word': str(text_word_translation.word),
                'translation': text_word_translation.to_dict()
            }))

        except (TextWord.DoesNotExist, DatabaseError):
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))


