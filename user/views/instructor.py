import json
from typing import TypeVar

from django import forms
from django.contrib.auth import login
from django.http import HttpResponse
from django.urls import reverse
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from user.forms import InstructorSignUpForm, InstructorLoginForm
from user.views.api import APIView
from user.views.base import ProfileView


class InstructorSignupAPIView(APIView):
    form = InstructorSignUpForm

    def post_success(self, instructor_signup_form: TypeVar('forms.Form')) -> HttpResponse:
        instructor = instructor_signup_form.save()

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-login')}))


class InstructorLoginAPIView(APIView):
    form = InstructorLoginForm

    def post_success(self, instructor_login_form: TypeVar('forms.Form')) -> HttpResponse:
        reader_user = instructor_login_form.get_user()
        login(self.request, reader_user)

        instructor = reader_user.instructor

        return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-profile')}))


class InstructorLoginView(TemplateView):
    template_name = 'instructor/login.html'


class InstructorSignUpView(TemplateView):
    template_name = 'instructor/signup.html'


class InstructorProfileView(ProfileView):
    login_url = reverse_lazy('instructor-login')

    template_name = 'instructor/profile.html'

