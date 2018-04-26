import json

from django.db.models import ObjectDoesNotExist
from django.http import HttpResponse
from django.views.generic import View

from text.models import Text
from question.models import Question
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy


class QuestionAPIView(LoginRequiredMixin, View):
    model = Question
    login_url = reverse_lazy('student-login')

    def get(self, request, *args, **kwargs):
        if 'pk' in kwargs:
            try:
                question = Question.objects.get(pk=kwargs['pk'])

                return HttpResponse(json.dumps(question.to_dict()))
            except ObjectDoesNotExist:
                return HttpResponse(errors={"errors": {'question': "question with id {0} does not exist".format(
                    kwargs['pk'])
                }}, status=400)

        if 'text' in self.request.GET.keys():
            try:
                text = Text.objects.get(pk=self.request.GET['text'])

                return HttpResponse(json.dumps([question.to_dict() for question in text.questions.all()]))
            except ObjectDoesNotExist:
                return HttpResponse(errors={"errors": {'text': "text with id {0} does not exist".format(
                    self.request.GET['text'])
                }}, status=400)

        questions = [question.to_dict() for question in self.model.objects.all()]

        return HttpResponse(json.dumps(questions))
