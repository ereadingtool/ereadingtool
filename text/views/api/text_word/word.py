import json

import jsonschema

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from django.db import transaction, DatabaseError
from django.core.exceptions import ObjectDoesNotExist

from text.translations.models import TextWord

from text.phrase.models import TextPhrase, TextPhraseTranslation


class TextWordAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['post', 'put', 'delete']

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            text_word_add_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_word_add_params, TextWord.to_add_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_word = TextWord.create(**text_word_add_params)

            text_word_dict = text_word.to_dict()

            text_word_dict['id'] = text_word.pk

            return HttpResponse(json.dumps(text_word_dict))

        except DatabaseError:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            text_word_update_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_word_update_params, TextWord.to_update_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_phrase = TextPhrase.objects.get(id=kwargs['pk'])

            updated_grammeme_params = text_word_update_params.pop('grammemes')

            with transaction.atomic():
                updated = text_phrase._meta.managers[0].filter(pk=text_phrase.pk).update(**updated_grammeme_params)

                if updated:
                    for grammeme, grammeme_value in updated_grammeme_params.items():
                        setattr(text_phrase, grammeme, grammeme_value)

                text_word_dict = text_phrase.to_translations_dict()

                text_word_dict['id'] = text_phrase.pk

            return HttpResponse(json.dumps(text_word_dict))

        except DatabaseError:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))


class TextWordTranslationsAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['put', 'post', 'delete']

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            text_phrase_translation = TextPhraseTranslation.objects.get(id=kwargs['tr_pk'])

            text_word_translation_dict = text_phrase_translation.to_dict()

            deleted, deleted_objs = text_phrase_translation.delete()

            return HttpResponse(json.dumps({
                'word': str(text_phrase_translation.text_phrase.phrase),
                'instance': text_phrase_translation.text_phrase.instance,
                'translation': text_word_translation_dict,
                'deleted': deleted >= 1
            }))

        except (ObjectDoesNotExist, DatabaseError):
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text_word_add_translation_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_word_add_translation_params, TextPhraseTranslation.to_add_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            with transaction.atomic():
                text_phrase = TextPhrase.objects.get(id=kwargs['pk'])

                text_word_add_translation_params['text_phrase'] = text_phrase

                if 'correct_for_context' in text_word_add_translation_params and text_word_add_translation_params[
                   'correct_for_context']:
                    TextPhraseTranslation.objects.filter(text_phrase=text_phrase).update(correct_for_context=False)

                text_phrase_translation = TextPhraseTranslation.create(**text_word_add_translation_params)

                return HttpResponse(json.dumps({
                    'word': str(text_phrase_translation.text_phrase.phrase),
                    'instance': text_phrase.instance,
                    'translation': text_phrase_translation.to_dict()
                }))

        except (TextPhrase.DoesNotExist, DatabaseError):
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_phrase_translation = None

        if 'tr_pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text_translation_update_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(text_translation_update_params, TextPhraseTranslation.to_update_json_schema())

        except json.JSONDecodeError as decode_error:
            return HttpResponse(json.dumps({'errors': {'json': str(decode_error)}}), status=400)

        except jsonschema.ValidationError as validation_error:
            return HttpResponse(json.dumps({'errors': {'json': str(validation_error)}}), status=400)

        try:
            text_phrase_translation = TextPhraseTranslation.objects.get(id=kwargs['tr_pk'])

            with transaction.atomic():
                # set all other translations to correct_for_context=False
                TextPhraseTranslation.objects.filter(
                    text_phrase=text_phrase_translation.text_phrase).update(correct_for_context=False)

                TextPhraseTranslation.objects.filter(pk=kwargs['tr_pk']).update(**text_translation_update_params)

            text_phrase_translation.refresh_from_db()

            return HttpResponse(json.dumps({
                'word': text_phrase_translation.text_phrase.phrase,
                'instance': text_phrase_translation.text_phrase.instance,
                'translation': text_phrase_translation.to_dict()
            }))

        except ObjectDoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
