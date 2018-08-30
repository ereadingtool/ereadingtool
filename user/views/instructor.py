import json
from typing import TypeVar

from django import forms
from django.contrib.auth import login, logout
from django.http import HttpResponse, HttpRequest, HttpResponseRedirect
from django.urls import reverse
from django.urls import reverse_lazy
from django.views.generic import TemplateView, View

from user.forms import InstructorSignUpForm, InstructorLoginForm
from user.views.api import APIView
from user.views.mixin import ProfileView
from django.contrib.auth.mixins import LoginRequiredMixin


class InstructorSignupAPIView(APIView):
    def form(self, request: HttpRequest, params: dict) -> TypeVar('forms.Form'):
        return InstructorSignUpForm(params)

    def post_success(self, instructor_signup_form: TypeVar('forms.Form')) -> HttpResponse:
        instructor = instructor_signup_form.save()

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-login')}))


class InstructorLoginAPIView(APIView):
    def form(self, request: HttpRequest, params: dict) -> TypeVar('forms.Form'):
        return InstructorLoginForm(request, params)

    def post_success(self, instructor_login_form: TypeVar('forms.Form')) -> HttpResponse:
        reader_user = instructor_login_form.get_user()

        if hasattr(reader_user, 'student'):
            return self.post_error({'all': 'Something went wrong.  Please try a different username and password.'})

        login(self.request, reader_user)

        instructor = reader_user.instructor

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-profile')}))


class InstructorLogoutAPIView(LoginRequiredMixin, View):
    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        logout(request)

        return HttpResponseRedirect(reverse_lazy('instructor-login'))


class InstructorLoginView(TemplateView):
    template_name = 'instructor/login.html'


class InstructorSignUpView(TemplateView):
    template_name = 'instructor/signup.html'


class InstructorProfileView(ProfileView):
    login_url = reverse_lazy('instructor-login')

    template_name = 'instructor/profile.html'

