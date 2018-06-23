import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from quiz.models import Quiz


class QuizLockAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')

    model = Quiz

    allowed_methods = ['post', 'delete']

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            if quiz.is_locked():
                return HttpResponseServerError(json.dumps({'errors':
                                                           'quiz is locked by {0}'.format(quiz.write_locker)}))

            locked = quiz.lock(self.request.user.instructor)

            return HttpResponse(json.dumps({'locked': locked}))
        except Quiz.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            if quiz.is_locked() and quiz.write_locker != self.request.user.instructor:
                return HttpResponseServerError(json.dumps({'errors':
                                                           'quiz is locked by {0}'.format(quiz.write_locker)}))

            locked = quiz.unlock()

            return HttpResponse(json.dumps({'locked': locked}))
        except Quiz.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
