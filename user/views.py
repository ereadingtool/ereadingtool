import json

from django.http import HttpResponse
from django.views.generic import TemplateView
from django.views.generic import View
from django.urls import reverse

from user.forms import InstructorSignUpForm, InstructorLoginForm, forms


class InstructorSignupAPIView(View):
    def post(self, request, *args, **kwargs):
        errors = {}

        def form_validation_errors(form: forms.ModelForm) -> dict:
            return {k: str(form.errors[k].data[0].message) for k in form.errors.keys()}

        try:
            signup_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={'errors': {'json': str(e)}}, status=400)

        instructor_signup_form = InstructorSignUpForm(signup_params)

        if not instructor_signup_form.is_valid():
            errors = form_validation_errors(instructor_signup_form)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
            instructor = instructor_signup_form.save()

            return HttpResponse(json.dumps({'id': instructor.pk, 'redirect': reverse('instructor-login')}))


class InstructorLoginAPIView(View):
    def post(self, request, *args, **kwargs):
        errors = {}

        def form_validation_errors(form: forms.ModelForm) -> dict:
            return {k: str(form.errors[k].data[0].message) for k in form.errors.keys()}

        try:
            login_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={"errors": {'json': str(e)}}, status=400)

        instructor_login_form = InstructorLoginForm(login_params)

        if not instructor_login_form.is_valid():
            errors = form_validation_errors(instructor_login_form)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
            return HttpResponse(json.dumps({"login": True}))


class InstructorLoginView(TemplateView):
    template_name = 'instructor_login.html'


class InstructorSignUpView(TemplateView):
    template_name = 'instructor_signup.html'
