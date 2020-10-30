import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.db import IntegrityError
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse_lazy
from ereadingtool.views import APIView
from text.models import Text
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from auth.normal_auth import jwt_valid

@method_decorator(csrf_exempt, name='dispatch') 
class TextTagAPIView(LoginRequiredMixin, APIView):
    login_url = reverse_lazy('instructor-login')

    model = Text

    allowed_methods = ['get', 'put', 'delete']

    @jwt_valid(403, {})
    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            tag = json.loads(request.body.decode('utf8'))
            text = Text.objects.get(pk=kwargs['pk'])

            try:
                text.remove_tag(tag)

                return HttpResponse(json.dumps(True))
            except IntegrityError:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponseServerError(json.dumps({'errors': 'tag not valid'}))

    @jwt_valid(403, {})
    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            tag = json.loads(request.body.decode('utf8'))
            text = Text.objects.get(pk=kwargs['pk'])

            try:
                text.add_tags(tag)

                return HttpResponse(json.dumps(True))
            except IntegrityError:
                return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponseServerError(json.dumps({'errors': 'tag not valid'}))

    @jwt_valid(403, {})
    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text = Text.objects.get(pk=kwargs['pk'])

            try:
                tags = [tag.name for tag in text.tags.all()]

                return HttpResponse(json.dumps(tags))
            except IntegrityError:
                return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponseServerError(json.dumps({'errors': 'tag not valid'}))
