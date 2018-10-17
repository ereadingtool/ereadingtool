from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import View

from text.definitions.models import TextDefinitions


class TextSectionDefinitionAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['get', 'put', 'post', 'delete']

    model = TextDefinitions
