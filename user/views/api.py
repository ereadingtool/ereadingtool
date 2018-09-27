import json
from typing import TypeVar

from django import forms
from django.http import HttpResponse, HttpRequest
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_protect
from django.views.decorators.debug import sensitive_post_parameters
from django.views.generic import View


class APIView(View):
    def form(self, request: HttpRequest, params: dict) -> TypeVar('forms.Form'):
        raise NotImplementedError

    def post_success(self, request: HttpRequest, form: TypeVar('forms.Form')) -> HttpResponse:
        raise NotImplementedError

    @method_decorator(sensitive_post_parameters())
    @method_decorator(csrf_protect)
    @method_decorator(never_cache)
    def dispatch(self, request, *args, **kwargs):
        return super(APIView, self).dispatch(request, *args, **kwargs)

    def format_form_errors(self, form: TypeVar('forms.Form')) -> dict:
        errors = {k: str(' '.join(form.errors[k])) for k in form.errors.keys()}

        # convert special Django form field error __all__ to something more frontend-friendly
        if '__all__' in errors:
            errors['all'] = errors.pop('__all__')

        return errors

    def post_json_error(self, error: json.JSONDecodeError) -> HttpResponse:
        return HttpResponse(errors={"errors": {'json': str(error)}}, status=400)

    def post_error(self, errors: dict) -> HttpResponse:
        return HttpResponse(json.dumps(errors), status=400)

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        errors = params = {}

        try:
            params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return self.post_json_error(e)

        form = self.form(request, params)

        if not form.is_valid():
            errors = self.format_form_errors(form)

        if errors:
            return self.post_error(errors)
        else:
            return self.post_success(request, form)
