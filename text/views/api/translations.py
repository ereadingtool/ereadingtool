import json

import jsonschema

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from django.db import transaction, DatabaseError

from text.translations.models import TextWordTranslation, TextWord


class TextTranslationMergeAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['put']

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            translation_merge_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(translation_merge_params, {
                'type': 'object',
                'properties': {
                    'translations': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'correct_for_context': {'type': 'boolean'},
                                'phrase': {'type': 'string'},
                            }
                        },
                        'minItems': 1
                    },
                    'text_word_ids': {
                        'type': 'array',
                        'items': {
                            'type': 'integer',
                        },
                        'minItems': 1
                    }
                }
            })

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_words = []

            for text_word_id in translation_merge_params['text_word_ids']:
                text_word = TextWord.objects.get(pk=text_word_id)

                with transaction.atomic():
                    TextWordTranslation.objects.filter(pk=text_word.pk).delete()

                    for translation in translation_merge_params['translations']:
                        translation['word'] = text_word
                        text_words.append(text_word)

            return HttpResponse(json.dumps([{
                'word': text_word.word,
                'grammemes': text_word.grammemes,
                'translation':
                    [translation.to_dict() for translation in text_word.translations]
                    if text_word.translations else None
            } for text_word in text_words]))

        except (DatabaseError, TextWord.DoesNotExist) as e:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))


class TextTranslationAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['put']

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_word_translation = None

        if 'tr_pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text_translation_update_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_translation_update_params, TextWordTranslation.to_update_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_word_translation = TextWordTranslation.objects.get(pk=kwargs['tr_pk'])

            with transaction.atomic():
                TextWordTranslation.objects.filter(word=text_word_translation.word).update(correct_for_context=False)
                TextWordTranslation.objects.filter(pk=kwargs['tr_pk']).update(**text_translation_update_params)

            text_word_translation.refresh_from_db()

            return HttpResponse(json.dumps({
                'word': str(text_word_translation.word),
                'translation': text_word_translation.to_dict()
            }))

        except TextWordTranslation.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
