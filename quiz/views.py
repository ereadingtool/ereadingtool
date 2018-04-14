from django.views.generic import TemplateView

from text.models import Text


class QuizView(TemplateView):
    model = Text
    template_name = 'quiz.html'
