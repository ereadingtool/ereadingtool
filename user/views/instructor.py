import json
from typing import TypeVar, Dict

from django import forms
from django.contrib.auth import login, logout
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.urls import reverse

from django.views.generic import TemplateView, View
from django.http import JsonResponse

from user.forms import InstructorSignUpForm, InstructorLoginForm, InstructorInviteForm

from user.instructor.models import Instructor

from user.views.api import APIView
from user.views.mixin import ProfileView

from mixins.view import NoAuthElmLoadJsView, ElmLoadJsInstructorBaseView

from jwt_auth.views import jwt_encode_token, jwt_get_json_with_token


Form = TypeVar('Form', bound=forms.Form)


class ElmLoadJsInstructorProfileView(ElmLoadJsInstructorBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsInstructorProfileView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.instructor
        except Instructor.DoesNotExist:
            pass

        context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                'value': json.dumps(profile.to_dict()) or 'null'}

        context['elm']['instructor_invite_uri'] = {'quote': True, 'safe': True,
                                                   'value': reverse('api-instructor-invite')}

        return context


class ElmLoadJsInstructorNoAuthView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsInstructorNoAuthView, self).get_context_data(**kwargs)

        def url_elm_value(url):
            return {'quote': True, 'safe': True, 'value': url}

        context['elm'].update({
            'user_type': {'quote': True, 'safe': True, 'value': 'instructor'},
            'instructor_signup_uri': url_elm_value(reverse('api-instructor-signup')),
            'signup_page_url': url_elm_value(reverse('instructor-signup')),

            'login_uri': url_elm_value(reverse('api-instructor-login')),
            'login_page_url': url_elm_value(reverse('student-login')),

            'reset_pass_endpoint': url_elm_value(reverse('api-password-reset')),
            'forgot_pass_endpoint': url_elm_value(reverse('api-password-reset-confirm')),
            'forgot_password_url': url_elm_value(reverse('password-reset')),

            'acknowledgements_url': url_elm_value(reverse('acknowledgements')),
            'about_url': url_elm_value(reverse('about'))
        })

        return context


class InstructorView(ProfileView):
    profile_model = Instructor
    login_url = Instructor.login_url


class InstructorInviteAPIView(LoginRequiredMixin, APIView):
    login_url = Instructor.login_url

    def dispatch(self, request, *args, **kwargs):
        if not (hasattr(request.user, 'profile') and
                isinstance(request.user.profile, Instructor) and
                request.user.profile.is_admin):
            return HttpResponseForbidden()

        return super(InstructorInviteAPIView, self).dispatch(request, *args, **kwargs)

    def form(self, request: HttpRequest, params: Dict) -> forms.ModelForm:
        return InstructorInviteForm(params, initial={'inviter': self.request.user.profile.pk})

    def post_success(self, request: HttpRequest, instructor_invite_form: Form) -> HttpResponse:
        invite = instructor_invite_form.save()

        return HttpResponse(json.dumps(invite.to_dict()), status=200)


class InstructorSignupAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> forms.ModelForm:
        return InstructorSignUpForm(params)

    def post_success(self, request: HttpRequest, instructor_signup_form: Form) -> HttpResponse:
        instructor = instructor_signup_form.save()

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-login')}))


class InstructorLoginAPIView(APIView):
    http_method_names = ['post']

    def form(self, request: HttpRequest, params: Dict) -> Form:
        return InstructorLoginForm(params)

    def post_success(self, request: HttpRequest, instructor_login_form: Form) -> JsonResponse:
        reader_user = instructor_login_form.get_user()

        token = jwt_encode_token(
            instructor_login_form.cleaned_data['user'], instructor_login_form.cleaned_data.get('orig_iat')
        )

        if hasattr(reader_user, 'student'):
            return self.post_error({'all': 'Something went wrong.  Please try a different username and password.'})

        jwt_payload = jwt_get_json_with_token(token)

        instructor = reader_user.instructor

        # customize payload re-using only the 'original issued at time' and expiration
        final_payload = {
            'id': instructor.pk,
            'orig_iat': jwt_payload['orig_iat'],
            'exp': jwt_payload['exp']
        }

        return JsonResponse(jwt_get_json_with_token(token))


class InstructorLogoutAPIView(LoginRequiredMixin, View):
    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        logout(request)

        return HttpResponse(json.dumps({'redirect': reverse('instructor-login')}))


class InstructorLoginView(TemplateView):
    template_name = 'instructor/login.html'

    def get_context_data(self, **kwargs):
        context = super(InstructorLoginView, self).get_context_data(**kwargs)

        context['title'] = 'Instructor Login'

        return context


class InstructorSignUpView(TemplateView):
    template_name = 'instructor/signup.html'

    def get_context_data(self, **kwargs):
        context = super(InstructorSignUpView, self).get_context_data(**kwargs)

        context['title'] = 'Instructor Signup'

        return context


class InstructorProfileView(InstructorView, TemplateView):
    template_name = 'instructor/profile.html'

    def get_context_data(self, **kwargs):
        context = super(InstructorProfileView, self).get_context_data(**kwargs)

        context['title'] = 'Instructor Profile'

        return context
