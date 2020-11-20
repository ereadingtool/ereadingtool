import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from ereadingtool.views import APIView

from text.models import Text

from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from auth.normal_auth import jwt_valid

@method_decorator(csrf_exempt, name='dispatch')
class TextLockAPIView(LoginRequiredMixin, APIView):
    login_url = reverse_lazy('instructor-login')

    model = Text

    allowed_methods = ['post', 'delete']

    @jwt_valid()
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

    @jwt_valid()
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
