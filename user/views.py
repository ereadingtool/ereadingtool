import json

from django.http import HttpResponse
from django.views.generic import TemplateView
from django.views.generic import View


from user.forms import InstructorSignUpForm, ModelForm


class InstructorSignupAPIView(View):
    def post(self, request, *args, **kwargs):
        errors = {}

        def form_validation_errors(form: ModelForm) -> dict:
            return {k: str(form.errors[k].data[0].message) for k in form.errors.keys()}

        try:
            signup_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={"errors": {'json': str(e)}}, status=400)

        instructor_signup_form = InstructorSignUpForm(signup_params)

        if not instructor_signup_form.is_valid():
            errors['signup'] = form_validation_errors(instructor_signup_form)

        if errors:
            return HttpResponse(json.dumps({
                '_'.join([k, k1]): v[k1] for (k, v) in errors.items() for k1 in v.keys()
            }), status=400)
        else:
            instructor = instructor_signup_form.save()

            return HttpResponse(json.dumps({"id": instructor.pk}))


class InstructorLoginAPIView(View):
    pass


class InstructorSignUpView(TemplateView):
    template_name = 'instructor_signup.html'
