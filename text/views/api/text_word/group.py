import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import View

from django.http import HttpResponse, HttpRequest, HttpResponseServerError

from django.db import transaction

from text.translations.models import TextWord
from text.translations.group.models import TextWordGroup, TextGroupWord


class TextWordGroupAPIView(LoginRequiredMixin, View):
    model = TextWordGroup

    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['post', 'put', 'delete']

    default_error_resp = HttpResponseServerError(json.dumps({'error': 'Something went wrong.'}),
                                                 content_type='application/json')

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_group_words = []

        resp = {
            'grouped': False,
            'error': None
        }

        try:
            text_word_ids = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError:
            resp['error'] = 'Something went wrong.'

            return HttpResponseServerError(json.dumps(resp))

        try:
            text_words = TextWord.objects.filter(pk__in=text_word_ids, group_word=None)
        except ValueError:
            # invalid ids
            resp['error'] = 'Something went wrong.'

            return self.default_error_resp

        with transaction.atomic():
            text_group = TextWordGroup.objects.create()

            # maintains order from parameter list
            for i, text_word in enumerate(text_words):
                text_group_words.append(TextGroupWord.objects.create(group=text_group, word=text_word, order=i))

        resp['grouped'] = True

        return HttpResponse(json.dumps(resp), status=200, content_type='application/json')

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            rows, deleted = TextWordGroup.objects.filter(pk=kwargs['pk']).delete()

            return HttpResponse(json.dumps({'deleted': rows > 0}), content_type='application/json')
        except (TextWordGroup.DoesNotExist, KeyError):
            return self.default_error_resp
