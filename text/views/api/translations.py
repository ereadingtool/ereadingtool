import json

import jsonschema
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from text.models import Text
from text.translations.models import TextWordTranslation


class TextTranslationAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['put']

    model = Text

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text = text_word_translation = None

        if 'text_pk' not in kwargs and 'tr_pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text_translation_update_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_translation_update_params, TextWordTranslation.to_update_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text = Text.objects.get(pk=kwargs['text_pk'])
            text_word_translation = TextWordTranslation.objects.get(pk=kwargs['tr_pk'])
            TextWordTranslation.objects.filter(pk=kwargs['tr_pk']).update(**text_translation_update_params)

        except (TextWordTranslation.DoesNotExist, Text.DoesNotExist) as e:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        return HttpResponse(json.dumps({
            'word': text_word_translation.word.word,
            'translation': text_word_translation.to_dict()
        }))
