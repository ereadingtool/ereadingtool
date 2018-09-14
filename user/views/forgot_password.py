import json
from typing import Dict
from typing import TypeVar

from django import forms
from django.contrib.auth.forms import PasswordResetForm, SetPasswordForm
from django.contrib.auth.tokens import default_token_generator
from django.http import HttpResponse, HttpRequest, HttpResponseRedirect
from django.views.generic import TemplateView

import ereadingtool.user as user_utils
from ereadingtool.user import INTERNAL_RESET_SESSION_TOKEN
from mixins.view import NoAuthElmLoadJsView
from user.views.api import APIView


class ElmLoadPassResetConfirmView(NoAuthElmLoadJsView):
    token_generator = default_token_generator

    def __init__(self, *args, **kwargs):
        super(ElmLoadPassResetConfirmView, self).__init__(*args, **kwargs)

        self.user = None
        self.validlink = False

    def dispatch(self, request, *args, **kwargs):
        session_token = self.request.session.get(INTERNAL_RESET_SESSION_TOKEN)

        self.user = user_utils.get_user(self.request.session.get('uidb64'))

        if self.token_generator.check_token(self.user, session_token):
            # If the token is valid, display the password reset form.
            self.validlink = True

            return super(ElmLoadPassResetConfirmView, self).dispatch(request, *args, **kwargs)

        return super(ElmLoadPassResetConfirmView, self).dispatch(request, *args, **kwargs)

    def get_context_data(self, **kwargs: Dict) -> Dict:
        context = super(ElmLoadPassResetConfirmView, self).get_context_data(**kwargs)

        context['elm']['validlink'] = {'quote': False, 'safe': True, 'value': 'true' if self.validlink else 'false'}

        context['elm']['uidb64'] = {'quote': True, 'safe': True, 'value': self.request.session.get('uidb64')}
        context['elm']['token'] = {'quote': True, 'safe': True, 'value': self.request.session.get('token')}

        return context


class PasswordResetView(TemplateView):
    template_name = 'registration/password_reset.html'


class PasswordResetConfirmView(TemplateView):
    template_name = 'registration/password_reset_confirm.html'
    token_generator = default_token_generator

    def __init__(self, *args, **kwargs):
        super(PasswordResetConfirmView, self).__init__(*args, **kwargs)

        self.user = None

    def dispatch(self, request, *args, **kwargs):
        assert 'uidb64' in kwargs and 'token' in kwargs

        self.user = user_utils.get_user(kwargs['uidb64'])

        if self.user is not None:
            token = kwargs['token']

            if token != user_utils.INTERNAL_RESET_URL_TOKEN:
                if self.token_generator.check_token(self.user, token):
                    # Store the token in the session and redirect to the
                    # password reset form at a URL without the token. That
                    # avoids the possibility of leaking the token in the
                    # HTTP Referer header.
                    self.request.session[user_utils.INTERNAL_RESET_SESSION_TOKEN] = token

                    # store uidb64 as well
                    self.request.session['uidb64'] = kwargs['uidb64']

                    redirect_url = self.request.path.replace(token, user_utils.INTERNAL_RESET_URL_TOKEN)

                    return HttpResponseRedirect(redirect_url)

        return super(PasswordResetConfirmView, self).dispatch(request, *args, **kwargs)


class PasswordResetConfirmAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> TypeVar('forms.Form'):
        user = user_utils.get_user(params.pop('uidb64'))

        return SetPasswordForm(user, params)

    def post_success(self, request: HttpRequest, form: TypeVar('forms.Form')):
        user = form.save()

        return HttpResponse(json.dumps({'errors': {}, 'body': 'Your password has been reset.',
                                        'redirect': user.profile.login_url}))


class PasswordResetAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> TypeVar('forms.Form'):
        return PasswordResetForm(params)

    def post_success(self, request: HttpRequest, form: TypeVar('forms.Form')):
        form.save(request=request)

        return HttpResponse(json.dumps({'errors': {},
                                        'body': 'An email has been sent to reset your password, '
                                                'if that e-mail exists in the system.'}), status=200)
