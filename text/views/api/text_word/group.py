import json

from django.db import models
from django.db import transaction
from django.http import HttpResponse, HttpRequest, HttpResponseServerError, response
from django.urls import reverse_lazy
from ereadingtool.views import APIView
from text.translations.group.models import TextWordGroup, TextGroupWord
from text.translations.models import TextWord
from text.phrase.models import TextPhrase
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from auth.normal_auth import jwt_valid

@method_decorator(csrf_exempt, name='dispatch')
class TextWordGroupAPIView(APIView):
    model = TextWordGroup

    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['post', 'put', 'delete']

    default_error_resp = HttpResponseServerError(json.dumps({'error': 'Something went wrong.'}),
                                                 content_type='application/json')

    @jwt_valid()
    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_group = None

        resp = {
            'phrase': '',   # TODO: lemma here?
            'section': None,
            'instance': 0,
            'grouped': False,
            'text_words': [],
            'error': None
        }

        try:
            text_word_ids = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError:
            return self.default_error_resp

        try:
            text_word_objs = {
                w.pk: w for w in
                TextWord.objects.filter(pk__in=text_word_ids).select_related('group_word', 'group_word__group')
            }

            # maintain order from parameter list
            text_words = [text_word_objs[text_word_id] for text_word_id in text_word_ids]
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
                text_group = TextWordGroup(text_section=text_words[0].text_section)

                text_group_text_words = list()

                phrases = []

                resp['instance'] = text_group.instance

                # maintain order from parameter list
                for i, text_word in enumerate(text_words):
                    phrases.append(text_word.phrase)

                    text_group_word = TextGroupWord(word=text_word, order=i)

                    text_group_text_words.append(text_group_word)

                    # avoids a call to refresh_from_db()
                    text_words[i].group_word = text_group_word

                resp['phrase'] = ' '.join(phrases)

                text_group.phrase = resp['phrase']
                text_group.save()

                for text_group_word in text_group_text_words:
                    text_group_word.group = text_group
                    text_group_word.save()

                resp['grouped'] = True
                resp['section'] = text_group.text_section.order
        else:
            try:
                first_text_word_group = text_words[0].group_word.group

                if all(map(lambda tw: group_for_text_word(tw) == first_text_word_group, text_words[1:])):
                    # words all belong to the same group already
                    text_group = first_text_word_group

                    resp['phrase'] = text_group.phrase # TODO: lemma here?
                    resp['section'] = text_group.text_section.order
                    resp['instance'] = text_group.instance
                    resp['grouped'] = True

            except (ValueError, IndexError):
                pass

        resp['text_words'] = [text_word.to_translations_dict() for text_word in text_words]

        if text_group:
            resp['text_words'].append(text_group.to_translations_dict())

        return HttpResponse(json.dumps(resp), status=200, content_type='application/json')


    @jwt_valid()
    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        try:
            group_id = request.path.split('/')[-1]
            words = TextGroupWord.objects.filter(group_id=group_id)
            words = [word.word_id for word in words]
            words.append(int(group_id)) # need to get the grouped word too
            response = TextPhrase.objects.get(pk=group_id).to_translations_dict()
            response['text_words'] = [TextPhrase.objects.get(pk=word).to_translations_dict() for word in words]
            response['section'] = response['text_section']
            del(response['text_section'])
            del(response['id'])
            del(response['grammemes'])
            del(response['group'])
            del(response['endpoints'])
            del(response['word_type'])
            del(response['translations'])

            try:
                rows, deleted = TextWordGroup.objects.filter(pk=kwargs['textphrase_ptr_id']).delete()
                response['deleted'] = rows > 0
                response['grouped'] = False
                response['error'] = None
            except (TextWordGroup.DoesNotExist, KeyError) as e:
                response['grouped'] = True
                response['error'] = f'missing {str(e)}' 

            return HttpResponse(json.dumps(response), content_type='application/json')
        except BaseException as be:
            return self.default_error_resp
