import json

from typing import TypeVar

from user.views.api import APIView

from django.views.generic import TemplateView

from django.http import HttpResponse, HttpRequest
from django.contrib.auth.forms import PasswordResetForm

from django import forms


class PasswordResetConfirmView(TemplateView):
    template_name = 'registration/password_reset_confirm.html'


class PasswordResetAPIView(APIView):
    def form(self, request: HttpRequest, params: dict):
        return PasswordResetForm(params)

    def post_success(self, request: HttpRequest, form: TypeVar('forms.Form')):
        form.save(request=request)

        return HttpResponse(json.dumps({'errors': {},
                                        'body': 'An email has been sent to reset your password, '
                                                'if that e-mail exists in the system.'}), status=200)
