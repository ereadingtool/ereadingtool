import json

from typing import Dict

from django.http import Http404
from django.http import HttpResponse, HttpRequest
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Text, TextDifficulty
from user.views.mixin import ProfileView


class TextSearchView(ProfileView, TemplateView):
    login_url = reverse_lazy('student-login')
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


class TextView(ProfileView, TemplateView):
    login_url = reverse_lazy('student-login')
    template_name = 'text.html'

    model = Text

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(TextView, self).get(request, *args, **kwargs)


class TextLoadElm(ElmLoadJsView):
    template_name = "load_elm.html"

    def get_context_data(self, **kwargs) -> Dict:
        context = super(TextLoadElm, self).get_context_data(**kwargs)

        context['elm']['text_id'] = {'quote': False, 'safe': True, 'value': context['pk']}

        return context

