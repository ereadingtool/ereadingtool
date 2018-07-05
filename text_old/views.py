import json

from django.db.models import ObjectDoesNotExist
from django.http import HttpResponse
from django.views.generic import View

from text_old.models import Text, TextDifficulty
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy


class TextAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('student-login')

    model = Text

    def get(self, request, *args, **kwargs):
        if 'difficulties' in request.GET.keys():
            return HttpResponse(json.dumps({d.slug: d.name for d in TextDifficulty.objects.all()}))

        if 'pk' in kwargs:
            try:
                text = Text.objects.get(pk=kwargs['pk'])

                return HttpResponse(json.dumps(text.to_dict()))
            except ObjectDoesNotExist:
                return HttpResponse(errors={"errors": {'text': "text with id {0} does not exist".format(
                    kwargs['pk'])
                }}, status=400)

        texts = [text.to_dict() for text in self.model.objects.all()]

        return HttpResponse(json.dumps(list(texts)))
