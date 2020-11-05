import json
import os
from typing import Dict
from django.http import JsonResponse
from django import forms
from django.urls import reverse
from django.contrib.auth.forms import PasswordResetForm, SetPasswordForm
from django.contrib.auth.tokens import default_token_generator
from django.http import HttpResponse, HttpRequest
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

    def get_context_data(self, **kwargs: Dict) -> Dict:
        context = super(ElmLoadPassResetConfirmView, self).get_context_data(**kwargs)

        context['elm']['validlink'] = {'quote': False, 'safe': True, 'value': 'true' if self.validlink else 'false'}

        context['elm']['uidb64'] = {'quote': True, 'safe': True, 'value': self.request.session.get('uidb64')}
        context['elm']['token'] = {'quote': True, 'safe': True, 'value': self.request.session.get('token')}
        context['elm']['forgot_pass_endpoint'] = {'quote': True, 'safe': True,
                                                  'value': reverse('api-password-reset-confirm')}

        return context


class ElmLoadPasswordResetView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs: Dict) -> Dict:
        context = super(ElmLoadPasswordResetView, self).get_context_data(**kwargs)

        context['elm']['forgot_pass_endpoint'] = {'quote': True, 'safe': True,
                                                  'value': reverse('api-password-reset')}

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

            # TODO: Big issue here, we need to ditch all Referer headers via SecurityMiddleware 
            # available in Django 3.0. Worst case we come up with another soln like nginx referer
            # policy or some other exit like strategy (as was previously implemented)
            # https://geekthis.net/post/hide-http-referer-headers/#exit-page-redirect
            if self.token_generator.check_token(self.user, token):
                return HttpResponse()
            else:
                return HttpResponse(errors={'errors': {'Invalid Token': 'You did not provide a valid token.'}}, status=403)


class PasswordResetConfirmAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> 'forms.Form':
        token_generator = default_token_generator
        user = user_utils.get_user(params.pop('uidb64'))
        try:
            if token_generator.check_token(user, params['token']):
                return SetPasswordForm(user, params)
        except:
            pass
        form = SetPasswordForm(user, params)
        form.add_error(None, "There's been a validation issue. Try getting another password reset email.") 

        return form
        

    def post_success(self, request: HttpRequest, form: 'forms.Form'):
        user = form.save()

        return HttpResponse(json.dumps({'errors': {}, 'body': 'Your password has been reset.',
                                        'redirect': str(user.profile.login_url)}))


    def post_error(self, errors: dict) -> JsonResponse:
        """ Things went wrong in the `post()` method below."""
        if not errors:
            errors['all'] = 'An unspecified error has occurred.'
            return JsonResponse(errors, status=400) 
        else:
            return JsonResponse(errors, status=403)


class PasswordResetAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> 'forms.Form':
        return PasswordResetForm(params)

    def post_success(self, request: HttpRequest, form: 'forms.Form'):
        domain_override = os.getenv("FRONTEND_HOST") 
        form.save(request=request, domain_override=domain_override)

        return HttpResponse(json.dumps({'errors': {},
                                        'body': 'An email has been sent to reset your password, '
                                                'if that e-mail exists in the system.'}), status=200)

        