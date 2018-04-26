import json

from django.contrib.auth import login
from django.http import HttpResponse
from django.urls import reverse
from django.views.generic import TemplateView
from django.urls import reverse_lazy


from text.models import TextDifficulty
from user.forms import StudentSignUpForm, StudentLoginForm
from user.views.api import APIView
from user.views.base import ProfileView


class StudentSignupAPIView(APIView):
    def post(self, request, *args, **kwargs):
        errors = {}

        try:
            signup_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={'errors': {'json': str(e)}}, status=400)

        student_signup_form = StudentSignUpForm(signup_params)

        if not student_signup_form.is_valid():
            errors = self.format_form_errors(student_signup_form)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
            student = student_signup_form.save()

            return HttpResponse(json.dumps({'id': student.pk, 'redirect': reverse('student-login')}))


class StudentLoginAPIView(APIView):
    def post(self, request, *args, **kwargs):
        errors = {}

        try:
            login_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={"errors": {'json': str(e)}}, status=400)

        student_login_form = StudentLoginForm(request, login_params)

        if not student_login_form.is_valid():
            errors = self.format_form_errors(student_login_form)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
            reader_user = student_login_form.get_user()
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
