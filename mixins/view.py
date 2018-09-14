import json

import ereadingtool.user as user_utils
from typing import Dict, AnyStr

from django.contrib.auth import get_user_model
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib.auth.tokens import default_token_generator
from django.core.exceptions import ValidationError
from django.db.models import ObjectDoesNotExist
from django.utils.http import urlsafe_base64_decode

from django.views.decorators.vary import vary_on_cookie
from django.views.generic import TemplateView
from rjsmin import jsmin

from text.models import TextDifficulty

UserModel = get_user_model()

INTERNAL_RESET_URL_TOKEN = 'set-password'
INTERNAL_RESET_SESSION_TOKEN = '_password_reset_token'


class ElmLoadJsBaseView(TemplateView):
    template_name = "load_elm_base.html"

    # @cache_control(private=True, must_revalidate=True)
    @vary_on_cookie
    def dispatch(self, request, *args, **kwargs):
        return super(ElmLoadJsBaseView, self).dispatch(request, *args, **kwargs)

    # minify js
    def render_to_response(self, context, **response_kwargs):
        response = super(ElmLoadJsBaseView, self).render_to_response(context, **response_kwargs)

        response.render()

        response.content = jsmin(response.content.decode('utf8'))

        return response

    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsBaseView, self).get_context_data(**kwargs)

        context.setdefault('elm', {})

        return context


class ElmLoadJsInstructorView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsInstructorView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.instructor
        except ObjectDoesNotExist:
            pass

        context['elm']['instructor_profile'] = {'quote': False, 'safe': True, 'value': profile or 'null'}

        return context


class ElmLoadJsStudentView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsStudentView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.student
        except ObjectDoesNotExist:
            pass

        context['elm']['instructor_profile'] = {'quote': False, 'safe': True, 'value': profile or 'null'}

        return context


class ElmLoadJsView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.student

            context['elm']['student_profile'] = {'quote': False, 'safe': True,
                                                 'value': json.dumps(profile.to_dict())}
            context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                    'value': 'null'}
        except ObjectDoesNotExist:
            profile = self.request.user.instructor

            context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                    'value': json.dumps(profile.to_dict())}
            context['elm']['student_profile'] = {'quote': False, 'safe': True,
                                                 'value': 'null'}

        context['elm']['profile_id'] = {
            'quote': False,
            'safe': True,
            'value': profile.pk
        }

        context['elm']['profile_type'] = {
            'quote': True,
            'safe': True,
            'value': profile.__class__.__name__.lower()
        }

        return context


class NoAuthElmLoadJsView(ElmLoadJsBaseView):
    pass


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


class ElmLoadStudentSignUpView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadStudentSignUpView, self).get_context_data(**kwargs)

        context['elm']['difficulties'] = {'quote': False, 'safe': True,
                                          'value':
                                              json.dumps([(text_difficulty.slug, text_difficulty.name)
                                                          for text_difficulty in TextDifficulty.objects.all()])}

        return context
