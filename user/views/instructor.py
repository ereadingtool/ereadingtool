import json
from typing import TypeVar, Dict

from django import forms
from django.contrib.auth import login, logout
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest
from django.urls import reverse

from django.views.generic import TemplateView, View

from user.forms import InstructorSignUpForm, InstructorLoginForm

from user.instructor.models import Instructor

from user.views.api import APIView
from user.views.mixin import ProfileView

from mixins.view import ElmLoadJsBaseView


class ElmLoadJsInstructorView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsInstructorView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.instructor
        except Instructor.DoesNotExist:
            pass

        context['elm']['instructor_profile'] = {'quote': False, 'safe': True, 'value': profile or 'null'}

        return context


class InstructorView(ProfileView):
    profile_model = Instructor
    login_url = Instructor.login_url


class InstructorSignupAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> TypeVar('forms.Form'):
        return InstructorSignUpForm(params)

    def post_success(self, request: HttpRequest, instructor_signup_form: TypeVar('forms.Form')) -> HttpResponse:
        instructor = instructor_signup_form.save()

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-login')}))


class InstructorLoginAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> TypeVar('forms.Form'):
        return InstructorLoginForm(request, params)

    def post_success(self, request: HttpRequest, instructor_login_form: TypeVar('forms.Form')) -> HttpResponse:
        reader_user = instructor_login_form.get_user()

        if hasattr(reader_user, 'student'):
            return self.post_error({'all': 'Something went wrong.  Please try a different username and password.'})

        login(self.request, reader_user)

        instructor = reader_user.instructor

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-profile')}))


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
