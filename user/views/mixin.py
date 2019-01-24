from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView

from django.http import HttpResponse
from django.http import HttpResponseRedirect

from django.urls import reverse_lazy
from user.mixins.models import Profile


class ProfileView(LoginRequiredMixin, TemplateView):
    @property
    def profile_model(self) -> 'Profile':
        raise NotImplementedError

    def get(self, request, *args, **kwargs) -> HttpResponse:
        if not isinstance(request.user.profile, self.profile_model):
            return HttpResponseRedirect(reverse_lazy('error-page'))

        return super(ProfileView, self).get(request, *args, **kwargs)
