import json

import jsonschema

from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.urls import reverse_lazy
from ereadingtool.views import APIView

from django.db import transaction, DatabaseError
from django.core.exceptions import ObjectDoesNotExist

from text.phrase.models import TextPhrase, TextPhraseTranslation

from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from auth.normal_auth import jwt_valid

@method_decorator(csrf_exempt, name='dispatch')
class TextTranslationMatchAPIView(APIView):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['put']

    @jwt_valid()
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

                # There is a notion "word_type" that comes from the frontend but causes an error on the back.
                # Since it's not actually a part of a TextPhrase it throws an exception. If one were to implement
                # "Save for All" they'd need to send "multiple" or something from the frontend. They they would
                # need to do something similar with the grouped words table- in particular change the textptr to
                # the new TextPhrase and have the translation point to that new TextPhrase too -- I think.
                try:
                    del(text_phrase['word_type'])
                except:
                    # It's not passed by the test suite.
                    pass

                text_phrase = TextPhrase.objects.get(**text_phrase)

                with transaction.atomic():
                    text_phrase.translations.filter().delete()

                    for translation in translation_merge_params['translations']:
                        translation['text_phrase'] = text_phrase
                        TextPhraseTranslation.create(**translation)

                    text_phrases.append(text_phrase)

            response = []

            for text_phrase in text_phrases:
                response.append(text_phrase.to_translations_dict())

            return HttpResponse(json.dumps(response), status=200)

        except (DatabaseError, ObjectDoesNotExist) as e:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
