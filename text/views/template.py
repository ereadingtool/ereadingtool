import json
from typing import Dict

from csp.decorators import csp_replace
from django.http import Http404
from django.http import HttpResponse, HttpRequest
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Text, TextDifficulty, text_statuses

from user.instructor.models import Instructor


class TextSearchView(TemplateView):
    template_name = 'text_search.html'

    def get(self, request, *args, **kwargs) -> HttpResponse:
        response = super(TextSearchView, self).get(request, *args, **kwargs)

        try:
            welcome_session_params = request.session['welcome']

            del welcome_session_params['student_search']

            request.session['welcome'] = welcome_session_params
        except KeyError:
            pass

        return response

    model = Text


class TextSearchLoadElm(ElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(TextSearchLoadElm, self).get_context_data(**kwargs)

        context['elm']['text_difficulties'] = {
            'quote': False,
            'safe': True,
            'value': [[d.slug, d.name] for d in TextDifficulty.objects.all()]
        }

        context['elm']['text_tags'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps([tag.name for tag in Text.tag_choices()])
        }

        context['elm']['text_statuses'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(text_statuses)
        }

        try:
            welcome = self.request.session['welcome']['student_search']
        except KeyError:
            welcome = False

        context['elm']['welcome'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(welcome)
        }

        return context


class TextView(TemplateView):
    template_name = 'text.html'

    model = Text

    # for text reading, relax connect-src CSP
    # since websockets are not the same origin as the HTTP requests (https://github.com/w3c/webappsec/issues/489)
    @csp_replace(CONNECT_SRC=("ws://*",))
    def dispatch(self, request, *args, **kwargs):
        return super(TextView, self).dispatch(request, *args, **kwargs)

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(TextView, self).get(request, *args, **kwargs)


class TextLoadElm(ElmLoadJsView):
    template_name = "load_elm.html"

    def get_context_data(self, **kwargs) -> Dict:
        context = super(TextLoadElm, self).get_context_data(**kwargs)

        host = self.request.get_host()

        profile = self.request.user.profile

        profile_type = 'student'

        if isinstance(profile, Instructor):
            profile_type = 'instructor'

        context['elm']['text_id'] = {'quote': False, 'safe': True, 'value': context['pk']}

        ws_addr = f"ws://{host}/{profile_type}/text_read/{context['pk']}/"

        context['elm']['text_reader_ws_addr'] = {'quote': True, 'safe': True,
                                                 'value': ws_addr}

        return context
