import json
from typing import TypeVar

from django import forms
from django.contrib.auth import login
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.urls import reverse
from django.urls import reverse_lazy
from django.views.generic import TemplateView

from text.models import TextDifficulty
from user.forms import StudentSignUpForm, StudentLoginForm, StudentForm
from user.models import Student
from user.views.api import APIView
from user.views.mixin import ProfileView, ElmLoadJsView
from django.contrib.auth.mixins import LoginRequiredMixin


class StudentAPIView(LoginRequiredMixin, APIView):
    # returns permission denied HTTP message rather than redirect to login
    raise_exception = True

    def form(self, request: HttpRequest, params: dict) -> TypeVar('forms.Form'):
        return StudentForm(params)

    def get(self, request, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).count():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponseForbidden()

        return HttpResponse(json.dumps(student.to_dict()))

    def post_success(self, form: TypeVar('forms.Form')) -> HttpResponse:
        raise NotImplementedError


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

    def get_context_data(self, **kwargs) -> dict:
        context = super(StudentSignUpView, self).get_context_data(**kwargs)

        context['difficulties'] = json.dumps([(text_difficulty.slug, text_difficulty.name)
                                              for text_difficulty in TextDifficulty.objects.all()])

        return context


class StudentLoginView(TemplateView):
    template_name = 'student/login.html'


class StudentLoadElm(ElmLoadJsView):
    def get_context_data(self, **kwargs):
        context = super(StudentLoadElm, self).get_context_data(**kwargs)

        context['elm']['difficulties'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps([(text_difficulty.slug, text_difficulty.name)
                                 for text_difficulty in TextDifficulty.objects.all()])
        }

        return context


class StudentProfileView(ProfileView):
    template_name = 'student/profile.html'
    login_url = reverse_lazy('student-login')

