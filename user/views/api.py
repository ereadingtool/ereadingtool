from auth.normal_auth import jwt_valid
import json

from django import forms
from django.http import JsonResponse, HttpRequest, HttpResponse
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.debug import sensitive_post_parameters
from django.views.generic import View
from user.forms import AuthenticationForm
from user.student.models import Student
from text.models import TextDifficulty

class APIView(View):
    def form(self, request: HttpRequest, params: dict) -> 'forms.Form':
        raise NotImplementedError

    def post_success(self, request: HttpRequest, form: 'forms.Form') -> JsonResponse:
        raise NotImplementedError

    @method_decorator(sensitive_post_parameters())
    @method_decorator(csrf_exempt)
    @method_decorator(never_cache)
    def dispatch(self, request, *args, **kwargs):
        # entry point for requests and utlimately sends out the response. Dispatches to the appropriate view?
        # https://stackoverflow.com/questions/47808652/what-is-dispatch-used-for-in-django
        return super(APIView, self).dispatch(request, *args, **kwargs)

    def format_form_errors(self, form: 'forms.Form') -> dict:
        errors = {k: str(' '.join(form.errors[k])) for k in form.errors.keys()}

        # convert special Django form field error __all__ to something more frontend-friendly
        if '__all__' in errors:
            errors['all'] = errors.pop('__all__')

        return errors

    def post_json_error(self, error: json.JSONDecodeError) -> JsonResponse:
        return JsonResponse({"errors": {'json': str(error)}}, status=400)

    def post_error(self, errors: dict) -> JsonResponse:
        """ Things went wrong in the `post()` method below."""
        if not errors:
            errors['all'] = 'An unspecified error has occurred.'

        return JsonResponse(errors, status=400)


    def post(self, request: HttpRequest, *args, **kwargs) -> JsonResponse:
        """
        APIView.dispatch() calls this method if the HttpRequest is of type POST
        It includes logic to determine if the form fields are valid, therefore it
        is considered a "bounded form". It also checks the credentials. 
        """
        errors = params = {}

        try:
            params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return self.post_json_error(e)

        try:
            form = self.form(request, params)

            # `is_valid()` has the ability to determine if a user enters invalid creds
            if form.is_valid():
                return self.post_success(request, form)
            else:
                errors = self.format_form_errors(form)
                return self.post_error(errors, request, form)
        except Exception as e:
            return self.post_error(errors)


    @jwt_valid()
    def put(self, request, *args, **kwargs) -> JsonResponse:
        errors = params = {}

        if not Student.objects.filter(pk=kwargs['pk']).exists():
            self.put_error(400, {})

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponse(status=403, content={'Error': 'Invalid token'}, content_type="application/json")

        try:
            params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return self.post_json_error(e)

        if 'difficulty_preference' in params:
            try:
                params['difficulty_preference'] = TextDifficulty.objects.get(slug=params['difficulty_preference']).pk
            except TextDifficulty.DoesNotExist:
                pass

        form = self.form(request, params, instance=student)

        if not form.is_valid():
            errors = self.format_form_errors(form)

        if errors:
            return self.put_error(400, errors)
        else:
            return self.put_success(request, form)