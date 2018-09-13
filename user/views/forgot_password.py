import json

from typing import TypeVar, Dict, AnyStr

from user.views.api import APIView

from django.views.generic import TemplateView
from django.http import HttpResponse, HttpRequest, HttpResponseRedirect

from django.core.exceptions import ValidationError

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import default_token_generator

from django.contrib.auth.forms import PasswordResetForm, SetPasswordForm

from django import forms
from django.utils.http import urlsafe_base64_decode

UserModel = get_user_model()

INTERNAL_RESET_URL_TOKEN = 'set-password'
INTERNAL_RESET_SESSION_TOKEN = '_password_reset_token'


class PasswordResetView(TemplateView):
    template_name = 'registration/password_reset.html'


class PasswordResetConfirmView(TemplateView):
    template_name = 'registration/password_reset_confirm.html'
    token_generator = default_token_generator

    def __init__(self, *args, **kwargs):
        super(PasswordResetConfirmView, self).__init__(*args, **kwargs)

        self.validlink = False
        self.user = None

    def dispatch(self, request, *args, **kwargs):
        assert 'uidb64' in kwargs and 'token' in kwargs

        self.validlink = False
        self.user = self.get_user(kwargs['uidb64'])

        if self.user is not None:
            token = kwargs['token']

            if token != INTERNAL_RESET_URL_TOKEN:
                if self.token_generator.check_token(self.user, token):
                    # Store the token in the session and redirect to the
                    # password reset form at a URL without the token. That
                    # avoids the possibility of leaking the token in the
                    # HTTP Referer header.
                    self.request.session[INTERNAL_RESET_SESSION_TOKEN] = token

                    redirect_url = self.request.path.replace(token, INTERNAL_RESET_URL_TOKEN)

                    return HttpResponseRedirect(redirect_url)

        return super(PasswordResetConfirmView, self).dispatch(request, *args, **kwargs)

    def get_user(self, uidb64: AnyStr):
        try:
            # urlsafe_base64_decode() decodes to bytestring
            uid = urlsafe_base64_decode(uidb64).decode()
            user = UserModel._default_manager.get(pk=uid)

        except (TypeError, ValueError, OverflowError, UserModel.DoesNotExist, ValidationError):
            user = None

        return user


class PasswordResetConfirmAPIView(APIView):
    def form(self, request: HttpRequest, params: dict):
        return SetPasswordForm(params)

    def post_success(self, request: HttpRequest, form: TypeVar('forms.Form')):
        form.save(request=request)

        return HttpResponse(json.dumps({'errors': {}, 'body': 'Your password has been reset.', 'redirect': ''}))


class PasswordResetAPIView(APIView):
    def form(self, request: HttpRequest, params: dict):
        return PasswordResetForm(params)

    def post_success(self, request: HttpRequest, form: TypeVar('forms.Form')):
        form.save(request=request)

        return HttpResponse(json.dumps({'errors': {},
                                        'body': 'An email has been sent to reset your password, '
                                                'if that e-mail exists in the system.'}), status=200)
