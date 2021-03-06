import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from text.models import Text


class TextLockAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')

    model = Text

    allowed_methods = ['post', 'delete']

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text = Text.objects.get(pk=kwargs['pk'])

            if text.is_locked():
                return HttpResponseServerError(json.dumps({'errors':
                                                           'text is locked by {0}'.format(text.write_locker)}))

            locked = text.lock(self.request.user.instructor)

            return HttpResponse(json.dumps({'locked': locked}))
        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text = Text.objects.get(pk=kwargs['pk'])

            if text.is_locked() and text.write_locker != self.request.user.instructor:
                return HttpResponseServerError(json.dumps({'errors':
                                                           'text is locked by {0}'.format(text.write_locker)}))

            locked = text.unlock()

            return HttpResponse(json.dumps({'locked': locked}))
        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
