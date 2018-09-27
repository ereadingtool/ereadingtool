import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.views.generic import View

from user.student.models import Student


class StudentPerformanceAPIView(LoginRequiredMixin, View):
    # returns permission denied HTTP message rather than redirect to login
    raise_exception = True

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).exists():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponseForbidden()

        return HttpResponse(json.dumps(student.performance.to_dict()))
