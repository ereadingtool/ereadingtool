import json
from typing import Dict

from csp.decorators import csp_replace
from django.http import Http404
from django.http import HttpResponse, HttpRequest
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Text, TextDifficulty, text_statuses

from user.instructor.models import Instructor
from django.conf import settings

from ereadingtool.menu import MenuItems


class TextSearchView(TemplateView):
    template_name = 'text_search.html'

    model = Text


class TextSearchLoadElm(ElmLoadJsView):
    def get_instructor_menu_items(self) -> MenuItems:
        instructor_menu_items = super(TextSearchLoadElm, self).get_instructor_menu_items()

        instructor_menu_items.select('text-search')

        return instructor_menu_items

    def get_student_menu_items(self) -> MenuItems:
        student_menu_items = super(TextSearchLoadElm, self).get_student_menu_items()

        student_menu_items.select('text-search')

        return student_menu_items

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
            welcome_student_search = self.request.session['welcome']['student_search']
        except KeyError:
            welcome_student_search = False

        try:
            student_session = self.request.session['welcome']

            del student_session['student_search']

            self.request.session['welcome'] = student_session
        except KeyError:
            pass

        context['elm']['welcome'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(welcome_student_search)
        }

        return context


class TextView(TemplateView):
    template_name = 'text.html'

    model = Text

    # for text reading, relax connect-src CSP
    # since websockets are not the same origin as the HTTP requests (https://github.com/w3c/webappsec/issues/489)
    # also relax style-src, since these come from CkEditor
    @csp_replace(CONNECT_SRC=("ws://*" if settings.DEV else "wss://*", "'self'"),
                 STYLE_SRC=("'self'", "'unsafe-inline'",))
    def dispatch(self, request, *args, **kwargs):
        return super(TextView, self).dispatch(request, *args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super(TextView, self).get_context_data()

        context['pk'] = kwargs['pk']
        context['text'] = self.model.objects.get(pk=kwargs['pk'])

        return context

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']).exists():
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

        scheme = "ws://" if settings.DEV else "wss://"

        ws_addr = f"{scheme}{host}/{profile_type}/text_read/{context['pk']}/"

        context['elm']['text_reader_ws_addr'] = {'quote': True, 'safe': True,
                                                 'value': ws_addr}

        context['elm']['flashcards'] = {'quote': False, 'safe': True, 'value': json.dumps([
            c.phrase.child_instance.to_text_reading_dict() for c in profile.flashcards.all()
        ])}

        return context
