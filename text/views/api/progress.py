import json
import jsonschema

from django.contrib.auth.mixins import LoginRequiredMixin
from django.db import IntegrityError
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from django.views.generic import View

from text.models import TextSection
from user.student.models import StudentProgress


class TextProgressAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('student-login')

    model = StudentProgress

    allowed_methods = ['put']

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            student = self.request.user.student
        except AttributeError:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        try:
            progress_params = json.loads(request.body.decode('utf8'))

            jsonschema.validate(progress_params, TextSection.to_json_schema())
        except (json.JSONDecodeError, jsonschema.ValidationError):
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        try:
            section = TextSection.objects.get(pk=kwargs['pk'])

            StudentProgress.completed(student, section)

            try:
                return HttpResponse(json.dumps({'updated': True}))
            except IntegrityError:
                return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        except (IntegrityError, TextSection.DoesNotExist):
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
