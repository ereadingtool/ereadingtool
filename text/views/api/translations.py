import json

import jsonschema

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.urls import reverse_lazy
from django.views.generic import View

from django.db import transaction, DatabaseError
from django.core.exceptions import ObjectDoesNotExist

from text.translations.mixins import TextPhraseTranslation
from text.translations.phrase import TextPhrase


class TextTranslationMergeAPIView(LoginRequiredMixin, View):
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
                text_phrase, create_translation = TextPhrase.get(**text_phrase)

                with transaction.atomic():
                    text_phrase._meta.model.objects.filter(word=text_phrase.pk).delete()

                    for translation in translation_merge_params['translations']:
                        translation['word'] = text_phrase
                        create_translation(**translation)

                    text_phrases.append(text_phrase)

            response = []

            for i, text_phrase in enumerate(text_phrases):
                response.append({
                    'id': text_phrase.id,
                    'instance': i,
                    'word': text_phrase.word.lower(),
                    'grammemes': text_phrase.grammemes,
                    'translations':
                        [translation.to_dict() for translation in text_phrase.translations.all()]
                        if text_phrase.translations.exists() else None
                })

            return HttpResponse(json.dumps(response), status=200)

        except (DatabaseError, ObjectDoesNotExist) as e:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
