import json
from typing import TypeVar

from django.contrib.auth import login
from django.http import HttpResponse
from django.urls import reverse
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_protect
from django.views.decorators.debug import sensitive_post_parameters
from django.views.generic import TemplateView
from django.views.generic import View

from user.forms import InstructorSignUpForm, InstructorLoginForm, forms


class APIView(View):
    @method_decorator(sensitive_post_parameters())
    @method_decorator(csrf_protect)
    @method_decorator(never_cache)
    def dispatch(self, request, *args, **kwargs):
        return super(APIView, self).dispatch(request, *args, **kwargs)

    def format_form_errors(self, form: TypeVar('forms.Form')) -> dict:
        return {k: str(' '.join(form.errors[k])) for k in form.errors.keys()}


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
    template_name = 'instructor_login.html'


class InstructorSignUpView(TemplateView):
    template_name = 'instructor_signup.html'


class InstructorProfileView(TemplateView):
    template_name = 'instructor_profile.html'
