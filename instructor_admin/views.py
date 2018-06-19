import json

from csp.decorators import csp_replace
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import Http404
from django.http import HttpResponse
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from quiz.models import Quiz
from user.views.mixin import ProfileView


class AdminView(ProfileView, LoginRequiredMixin, TemplateView):
    login_url = reverse_lazy('instructor-login')


class QuizAdminView(AdminView):
    model = Quiz
    template_name = 'instructor_admin/admin.html'


class AdminCreateEditQuizView(AdminView):
    model = Quiz

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/create_edit_quiz.html'

    def get(self, request, *args, **kwargs) -> HttpResponse:
        if 'pk' in kwargs and not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('quiz does not exist')

        return super(AdminCreateEditQuizView, self).get(request, *args, **kwargs)

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
            except Quiz.DoesNotExist:
                pass

        context['elm']['quiz'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(quiz.to_dict() if quiz else None)
        }

        context['elm']['tags'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps([tag.name for tag in Quiz.tag_choices()])
        }

        return context
