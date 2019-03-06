import json

import jsonschema

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.urls import reverse_lazy
from django.views.generic import View

from django.db import transaction, DatabaseError
from django.core.exceptions import ObjectDoesNotExist

from text.phrase.models import TextPhrase, TextPhraseTranslation


class TextTranslationMatchAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['put']

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            translation_merge_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(translation_merge_params, TextPhraseTranslation.to_merge_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_phrases = []

            for text_phrase in translation_merge_params['words']:
                text_phrase, create_translation = TextPhrase.objects.get(**text_phrase)

                with transaction.atomic():
                    text_phrase.translations.filter().delete()

                    for translation in translation_merge_params['translations']:
                        translation['word'] = text_phrase
                        create_translation(**translation)

                    text_phrases.append(text_phrase)

            response = []

            for text_phrase in text_phrases:
                response.append(text_phrase.to_translations_dict())

            return HttpResponse(json.dumps(response), status=200)

        except (DatabaseError, ObjectDoesNotExist) as e:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
