from django.views.generic import TemplateView
from user.views.mixin import ProfileView, ElmLoadJsView
from django.urls import reverse_lazy
from text.models import Text


class QuizView(ProfileView, TemplateView):
    login_url = reverse_lazy('student-login')
    template_name = 'quiz.html'

    model = Text


class QuizLoadElm(ElmLoadJsView):
    def get_context_data(self, **kwargs):
        context = super(QuizLoadElm, self).get_context_data(**kwargs)

        context['elm']['quiz_id'] = {'quote': False, 'safe': True, 'value': context['pk']}

        return context

