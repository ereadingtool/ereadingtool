import json

from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from text.models import Text
from user.views.mixin import ProfileView
from mixins.view import ElmLoadJsView
from csp.decorators import csp_replace

from django.core.exceptions import ObjectDoesNotExist

from quiz.models import Quiz


class AdminView(ProfileView, LoginRequiredMixin, TemplateView):
    login_url = reverse_lazy('instructor-login')


class TextAdminView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/admin.html'


class AdminCreateEditQuizView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/create_edit_quiz.html'

    # for CkEditor, allow exceptions to the CSP rules for unsafe-inline code and styles.
    @csp_replace(STYLE_SRC=("'self'", "'unsafe-inline'",), SCRIPT_SRC=("'self'", "'unsafe-inline'",))
    def dispatch(self, request, *args, **kwargs):
        return super(AdminCreateEditQuizView, self).dispatch(request, *args, **kwargs)


class AdminCreateEditElmLoadView(ElmLoadJsView):
    template_name = "instructor_admin/load_elm.html"

    def get_context_data(self, **kwargs):
        context = super(AdminCreateEditElmLoadView, self).get_context_data(**kwargs)
        quiz = None

        if 'pk' in context:
            try:
                quiz = Quiz.objects.get(pk=context['pk'])
            except ObjectDoesNotExist:
                pass

        context['elm']['quiz'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(quiz.to_dict()) if quiz else "null"
        }

        return context
