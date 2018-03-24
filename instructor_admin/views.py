import json

from django.http import HttpResponse
from django.views.generic import TemplateView, View
from text.models import Text


class AdminView(TemplateView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'admin.html'


class AdminCreateQuizView(TemplateView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'create_quiz.html'


class AdminAPIView(View):
    model = Text

    def get(self, request):
        texts = [text.to_dict() for text in self.model.objects.all()]

        return HttpResponse(json.dumps(list(texts)))
