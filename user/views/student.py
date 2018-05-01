import json
from typing import TypeVar

from django import forms
from django.contrib.auth import login
from django.http import HttpResponse, HttpRequest
from django.urls import reverse
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from text.models import TextDifficulty
from user.forms import StudentSignUpForm, StudentLoginForm
from user.views.api import APIView
from user.views.base import ProfileView


class StudentSignupAPIView(APIView):
    def form(self, request: HttpRequest, params: dict) -> TypeVar('forms.Form'):
        return StudentSignUpForm(params)

    def post_success(self, student_signup_form: TypeVar('forms.Form')) -> HttpResponse:
        student = student_signup_form.save()

        return HttpResponse(json.dumps({'id': student.pk, 'redirect': reverse('student-login')}))


class StudentLoginAPIView(APIView):
    def form(self, request: HttpRequest, params: dict) -> TypeVar('forms.Form'):
        return StudentLoginForm(request, params)

    def post_success(self, student_login_form: TypeVar('forms.Form')) -> HttpResponse:
        reader_user = student_login_form.get_user()

        if hasattr(reader_user, 'instructor'):
            return self.post_error({'all': 'Something went wrong.  Please try a different username and password.'})

        login(self.request, reader_user)

        student = reader_user.student

        return HttpResponse(json.dumps({'id': student.pk, 'redirect': reverse('student-profile')}))


class StudentSignUpView(TemplateView):
    template_name = 'student/signup.html'

    def get_context_data(self, **kwargs):
        context = super(StudentSignUpView, self).get_context_data(**kwargs)

        context['difficulties'] = json.dumps([(text_difficulty.slug, text_difficulty.name)
                                              for text_difficulty in TextDifficulty.objects.all()])

        return context


class StudentLoginView(TemplateView):
    template_name = 'student/login.html'


class StudentProfileView(ProfileView):
    template_name = 'student/profile.html'

    login_url = reverse_lazy('student-login')
