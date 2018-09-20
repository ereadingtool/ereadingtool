import json
from typing import Dict

from csp.decorators import csp_replace
from django.http import Http404
from django.http import HttpResponse, HttpRequest
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Text, TextDifficulty


class TextSearchView(TemplateView):
    template_name = 'text_search.html'

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

        context['elm']['text_id'] = {'quote': False, 'safe': True, 'value': context['pk']}
        context['elm']['text_reader_ws_addr'] = {'quote': True, 'safe': True,
                                                 'value': f"ws://{host}/text_read/{context['pk']}/"}

        return context

