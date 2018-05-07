from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView
from django.db.models import ObjectDoesNotExist


class ProfileView(LoginRequiredMixin, TemplateView):
    pass


class ElmLoadJsView(LoginRequiredMixin, TemplateView):
    template_name = "load_elm_base.html"

    def get_context_data(self, **kwargs) -> dict:
        context = super(ElmLoadJsView, self).get_context_data(**kwargs)

        context.setdefault('elm', {})

        profile = None

        try:
            profile = self.request.user.student
        except ObjectDoesNotExist:
            profile = self.request.user.instructor

        context['elm']['profile_id'] = {
            'quote': False,
            'safe': True,
            'value': profile.pk
        }

        context['elm']['profile_type'] = {
            'quote': True,
            'safe': True,
            'value': profile.__class__.__name__.lower()
        }

        return context
