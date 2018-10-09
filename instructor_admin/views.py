import json

from typing import Dict
from csp.decorators import csp_replace
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import Http404, HttpResponseRedirect
from django.http import HttpResponse
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from django.http import HttpResponse, HttpRequest

from mixins.view import ElmLoadJsView
from text.models import Text

from user.views.instructor import InstructorView


class AdminView(InstructorView, TemplateView):
    pass


class TextAdminView(AdminView):
    model = Text
    template_name = 'instructor_admin/admin.html'


class TextDefinitionElmLoadView(ElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(TextDefinitionElmLoadView, self).get_context_data(**kwargs)

        if 'pk' in context:
            try:
                text = Text.objects.get(pk=context['pk'])
                words, word_freqs = text.definitions

                context['elm']['words'] = {'quote': False, 'safe': True, 'value': words}
                context['elm']['word_frequencies'] = {'quote': False, 'safe': True, 'value': word_freqs}
            except Text.DoesNotExist:
                pass

        return context


class TextDefinitionView(AdminView):
    model = Text
    template_name = 'instructor_admin/text_definitions.html'

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(TextDefinitionView, self).get(request, *args, **kwargs)


class AdminCreateEditTextView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/create_edit_text.html'

    def get(self, request, *args, **kwargs) -> HttpResponse:
        if 'pk' in kwargs and not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(AdminCreateEditTextView, self).get(request, *args, **kwargs)

    # for CkEditor, allow exceptions to the CSP rules for unsafe-inline code and styles.
    @csp_replace(STYLE_SRC=("'self'", "'unsafe-inline'",), SCRIPT_SRC=("'self'", "'unsafe-inline'",))
    def dispatch(self, request, *args, **kwargs):
        return super(AdminCreateEditTextView, self).dispatch(request, *args, **kwargs)


class AdminCreateEditElmLoadView(ElmLoadJsView):
    template_name = 'instructor_admin/load_elm.html'

    def get_context_data(self, **kwargs):
        context = super(AdminCreateEditElmLoadView, self).get_context_data(**kwargs)
        text = None

        if 'pk' in context:
            try:
                text = Text.objects.get(pk=context['pk'])
            except Text.DoesNotExist:
                pass

        context['elm']['text'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(text.to_dict() if text else None)
        }

        context['elm']['tags'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps([tag.name for tag in Text.tag_choices()])
        }

        return context
