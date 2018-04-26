import json

from django.contrib.auth import login
from user.views.base import ProfileView
from django.http import HttpResponse
from django.urls import reverse
from django.views.generic import TemplateView
from django.urls import reverse_lazy

from user.forms import InstructorSignUpForm, InstructorLoginForm
from user.views.api import APIView


class InstructorSignupAPIView(APIView):
    def post(self, request, *args, **kwargs):
        errors = {}

        try:
            signup_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={'errors': {'json': str(e)}}, status=400)

        instructor_signup_form = InstructorSignUpForm(signup_params)

        if not instructor_signup_form.is_valid():
            errors = self.format_form_errors(instructor_signup_form)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
            instructor = instructor_signup_form.save()

            return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-login')}))


class InstructorLoginAPIView(APIView):
    def post(self, request, *args, **kwargs):
        errors = {}

        try:
            login_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={"errors": {'json': str(e)}}, status=400)

        instructor_login_form = InstructorLoginForm(request, login_params)

        if not instructor_login_form.is_valid():
            errors = self.format_form_errors(instructor_login_form)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
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

