import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import View

from django.http import HttpResponse, HttpRequest, HttpResponseServerError

from django.db import transaction

from django.db import models

from text.translations.models import TextWord
from text.translations.group.models import TextWordGroup, TextGroupWord


class TextWordGroupAPIView(LoginRequiredMixin, View):
    model = TextWordGroup

    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['post', 'put', 'delete']

    default_error_resp = HttpResponseServerError(json.dumps({'error': 'Something went wrong.'}),
                                                 content_type='application/json')

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_group = None

        resp = {
            'instance': 0,
            'phrase': '',
            'grouped': False,
            'text_words': [],
            'error': None
        }

        try:
            text_word_ids = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError:
            return self.default_error_resp

        try:
            text_words = TextWord.objects.filter(pk__in=text_word_ids).select_related('group_word', 'group_word__group')
        except ValueError:
            # invalid ids
            return self.default_error_resp

        def group_for_text_word(tw):
            try:
                return tw.group_word.group
            except (ValueError, models.ObjectDoesNotExist):
                return None

        if all(map(lambda tw: group_for_text_word(tw) is None, text_words)):
            # words can be grouped together since they do not belong to any current group
            with transaction.atomic():
                text_group = TextWordGroup.objects.create()

                phrases = []

                resp['instance'] = text_group.instance

                # maintain order from parameter list
                for i, text_word in enumerate(text_words):
                    phrases.append(text_word.word)

                    text_group_word = TextGroupWord.objects.create(group=text_group, word=text_word, order=i)

                    # avoids a call to refresh_from_db()
                    text_words[i].group_word = text_group_word

                resp['phrase'] = ' '.join(phrases)
                resp['grouped'] = True
        else:
            try:
                first_text_word_group = text_words[0].group_word.group

                if all(map(lambda tw: group_for_text_word(tw) == first_text_word_group, text_words[1:])):
                    # words all belong to the same group already
                    text_group = first_text_word_group

                    resp['instance'] = text_group.instance
                    resp['phrase'] = text_group.phrase
                    resp['grouped'] = True

            except (ValueError, IndexError):
                pass

        resp['text_words'] = [text_word.to_translations_dict() for text_word in text_words]

        if text_group:
            resp['text_words'].append(text_group.to_translations_dict())

        return HttpResponse(json.dumps(resp), status=200, content_type='application/json')

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            rows, deleted = TextWordGroup.objects.filter(pk=kwargs['pk']).delete()

            return HttpResponse(json.dumps({'deleted': rows > 0}), content_type='application/json')
        except (TextWordGroup.DoesNotExist, KeyError):
            return self.default_error_resp
