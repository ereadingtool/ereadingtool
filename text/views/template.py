from django.http import Http404
from django.http import HttpResponse, HttpRequest
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Quiz
from user.views.mixin import ProfileView


class QuizView(ProfileView, TemplateView):
    login_url = reverse_lazy('student-login')
    template_name = 'quiz.html'

    model = Quiz

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('quiz does not exist')

        return super(QuizView, self).get(request, *args, **kwargs)


class QuizLoadElm(ElmLoadJsView):
    def get_context_data(self, **kwargs) -> dict:
        context = super(QuizLoadElm, self).get_context_data(**kwargs)

        context['elm']['quiz_id'] = {'quote': False, 'safe': True, 'value': context['pk']}

        return context

