import json

from django.db.models import ObjectDoesNotExist
from django.core.exceptions import ValidationError
from django.http import HttpResponse
from django.views.generic import View
from ereadingtool.views import APIView

from text.models import Text
from question.models import Question
from django.urls import reverse_lazy

from auth.normal_auth import jwt_valid

#TODO: Verify this endpoint is hit
class QuestionAPIView(APIView):
    model = Question
    login_url = reverse_lazy('student-login')

    @jwt_valid()
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
                try:
                    int(self.request.GET['text'])
                except ValueError:
                    raise ValidationError(message='{0} is not a valid id'.format(self.request.GET['text']))

                text = Text.objects.get(pk=self.request.GET['text'])

                return HttpResponse(json.dumps([question.to_dict() for question in text.questions.all()]))
            except (ObjectDoesNotExist, ValidationError):
                return HttpResponse(json.dumps({"errors": {'text': "text with id {0} does not exist".format(
                    self.request.GET['text'])
                }}), status=400)

        questions = [question.to_dict() for question in self.model.objects.all()]

        return HttpResponse(json.dumps(questions))
