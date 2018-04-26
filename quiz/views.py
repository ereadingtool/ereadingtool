from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from text.models import Text


class QuizView(LoginRequiredMixin, TemplateView):
    login_url = reverse_lazy('student-login')

    model = Text
    template_name = 'quiz.html'
