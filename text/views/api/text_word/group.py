from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import View

from text.translations.group.models import TextWordGroup


class TextWordGroupAPIView(LoginRequiredMixin, View):
    model = TextWordGroup

    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['post', 'put', 'delete']
