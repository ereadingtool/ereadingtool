import json

from django import forms
from django.http import JsonResponse, HttpRequest
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from django.views.decorators.debug import sensitive_post_parameters

from ereadingtool.views import APIView as EreadingToolAPIView


class APIView(EreadingToolAPIView):
    def form(self, request: HttpRequest, params: dict) -> 'forms.Form':
        raise NotImplementedError

    def post_success(self, request: HttpRequest, form: 'forms.Form') -> JsonResponse:
        raise NotImplementedError

    @method_decorator(sensitive_post_parameters())
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

    # This is where form validation is done
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

        form = self.form(request, params)

        # `is_valid()` has the ability to determine if a user enters invalid creds
        form_is_valid = form.is_valid()

        if not form_is_valid:
            errors = self.format_form_errors(form)

        if form_is_valid:
            return self.post_success(request, form)
        else:
            return self.post_error(errors)
