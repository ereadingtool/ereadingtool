import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.db import IntegrityError
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from text.models import Quiz


class QuizTagAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')

    model = Quiz

    allowed_methods = ['get', 'put', 'delete']

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            tag = json.loads(request.body.decode('utf8'))
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                quiz.remove_tag(tag)

                return HttpResponse(json.dumps(True))
            except IntegrityError:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        except Quiz.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponseServerError(json.dumps({'errors': 'tag not valid'}))

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            tag = json.loads(request.body.decode('utf8'))
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                quiz.add_tags(tag)

                return HttpResponse(json.dumps(True))
            except IntegrityError:
                return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        except Quiz.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponseServerError(json.dumps({'errors': 'tag not valid'}))

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                tags = [tag.name for tag in quiz.tags.all()]

                return HttpResponse(json.dumps(tags))
            except IntegrityError:
                return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        except Quiz.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponseServerError(json.dumps({'errors': 'tag not valid'}))
