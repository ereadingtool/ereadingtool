from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView
from django.db.models import ObjectDoesNotExist


class ProfileView(LoginRequiredMixin, TemplateView):
    def get_context_data(self, **kwargs) -> dict:
        context = super(ProfileView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.student
        except ObjectDoesNotExist:
            profile = self.request.user.instructor

        context['profile_type'] = profile.__class__.__name__.lower()
        context['profile_id'] = profile.pk

        return context
