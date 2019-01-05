import json

from typing import TypeVar, Dict, Union

from django import forms
from django.contrib.auth import login, logout
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.urls import reverse

from django.views.generic import TemplateView, View

from text.models import TextDifficulty
from user.forms import StudentSignUpForm, StudentLoginForm, StudentForm
from user.student.models import Student
from user.views.api import APIView
from user.views.mixin import ProfileView
from django.contrib.auth.mixins import LoginRequiredMixin
from mixins.view import ElmLoadJsBaseView, NoAuthElmLoadJsView


Form = TypeVar('Form', bound=forms.Form)


class ElmLoadJsStudentView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsStudentView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.student
        except Student.DoesNotExist:
            pass

        context['elm']['profile_id'] = {'quote': False, 'safe': True, 'value': profile.id or 'null'}

        try:
            welcome = self.request.session['welcome']['student_profile']
        except KeyError:
            welcome = False

        context['elm']['welcome'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(welcome)
        }

        return context


class ElmLoadStudentSignUpView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadStudentSignUpView, self).get_context_data(**kwargs)

        context['elm']['difficulties'] = {'quote': False, 'safe': True,
                                          'value':
                                              json.dumps([(text_difficulty.slug, text_difficulty.name)
                                                          for text_difficulty in TextDifficulty.objects.all()])}

        return context


class StudentView(ProfileView):
    profile_model = Student
    login_url = Student.login_url


class StudentAPIView(LoginRequiredMixin, APIView):
    # returns permission denied HTTP message rather than redirect to login
    raise_exception = True

    def form(self, request: HttpRequest, params: dict, **kwargs) -> forms.ModelForm:
        return StudentForm(params, **kwargs)

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).count():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponseForbidden()

        return HttpResponse(json.dumps(student.to_dict()))

    def post_success(self, request: HttpRequest, form: Form) -> HttpResponse:
        raise NotImplementedError

    def put_error(self, errors: dict) -> HttpResponse:
        return HttpResponse(json.dumps(errors), status=400)

    def put_success(self, request: HttpRequest, student_form: Union[Form, forms.ModelForm]) -> HttpResponse:
        student = student_form.save()

        return HttpResponse(json.dumps(student.to_dict()))

    def put(self, request, *args, **kwargs) -> HttpResponse:
        errors = params = {}

        if not Student.objects.filter(pk=kwargs['pk']).count():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponseForbidden()

        try:
            params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return self.put_json_error(e)

        if 'difficulty_preference' in params:
            try:
                params['difficulty_preference'] = TextDifficulty.objects.get(slug=params['difficulty_preference']).pk
            except TextDifficulty.DoesNotExist:
                pass

        form = self.form(request, params, instance=student)

        if not form.is_valid():
            errors = self.format_form_errors(form)

        if errors:
            return self.put_error(errors)
        else:
            return self.put_success(request, form)


class StudentSignupAPIView(APIView):
    def form(self, request: HttpRequest, params: dict) -> forms.ModelForm:
        return StudentSignUpForm(params)

    def post_success(self, request: HttpRequest, student_signup_form: Form) -> HttpResponse:
        student = student_signup_form.save()

        request.session['welcome'] = {
            'student_profile': True,
            'student_search': True
        }

        return HttpResponse(json.dumps({'id': student.pk, 'redirect': reverse('student-login')}))


class StudentLogoutAPIView(LoginRequiredMixin, View):
    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        logout(request)

        return HttpResponse(json.dumps({'redirect': reverse('student-login')}))


class StudentLoginAPIView(APIView):
    def form(self, request: HttpRequest, params: dict) -> Form:
        return StudentLoginForm(request, params)

    def post_success(self, request: HttpRequest, student_login_form: Form) -> HttpResponse:
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

        context['title'] = 'Student Signup'

        context['difficulties'] = json.dumps([(text_difficulty.slug, text_difficulty.name)
                                              for text_difficulty in TextDifficulty.objects.all()])

        return context


class StudentLoginView(TemplateView):
    template_name = 'student/login.html'

    def get_context_data(self, **kwargs):
        context = super(StudentLoginView, self).get_context_data(**kwargs)

        context['title'] = 'Student Login'

        return context


class StudentProfileView(StudentView, TemplateView):
    template_name = 'student/profile.html'

    def get(self, request, *args, **kwargs) -> HttpResponse:
        response = super(StudentProfileView, self).get(request, *args, **kwargs)

        welcome_session_params = request.session['welcome']

        del welcome_session_params['student_profile']

        request.session['welcome'] = welcome_session_params

        return response

    def get_context_data(self, **kwargs):
        context = super(StudentProfileView, self).get_context_data(**kwargs)

        context['title'] = 'Student Profile'

        return context


class StudentFlashcardView(StudentView, TemplateView):
    template_name = 'student/flashcards.html'

    def get_context_data(self, **kwargs):
        context = super(StudentFlashcardView, self).get_context_data(**kwargs)

        context['title'] = 'Student Flashcards'

        return context
