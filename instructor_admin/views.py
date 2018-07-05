import json

from csp.decorators import csp_replace
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import Http404
from django.http import HttpResponse
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Text
from user.views.mixin import ProfileView


class AdminView(ProfileView, LoginRequiredMixin, TemplateView):
    login_url = reverse_lazy('instructor-login')


class TextAdminView(AdminView):
    model = Text
    template_name = 'instructor_admin/admin.html'


class AdminCreateEditTextView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/create_edit_quiz.html'

    def get(self, request, *args, **kwargs) -> HttpResponse:
        if 'pk' in kwargs and not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(AdminCreateEditTextView, self).get(request, *args, **kwargs)

    # for CkEditor, allow exceptions to the CSP rules for unsafe-inline code and styles.
    @csp_replace(STYLE_SRC=("'self'", "'unsafe-inline'",), SCRIPT_SRC=("'self'", "'unsafe-inline'",))
    def dispatch(self, request, *args, **kwargs):
        return super(AdminCreateEditTextView, self).dispatch(request, *args, **kwargs)


class AdminCreateEditElmLoadView(ElmLoadJsView):
    template_name = "instructor_admin/load_elm.html"

    def get_context_data(self, **kwargs):
        context = super(AdminCreateEditElmLoadView, self).get_context_data(**kwargs)
        text = None

        if 'pk' in context:
            try:
                text = Text.objects.get(pk=context['pk'])
            except Text.DoesNotExist:
                pass

        context['elm']['quiz'] = {
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
