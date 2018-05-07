import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView
from django.db.models import ObjectDoesNotExist


class ElmLoadJsView(LoginRequiredMixin, TemplateView):
    template_name = "load_elm_base.html"

    # minify js
    def render_to_response(self, context, **response_kwargs):
        response = super(ElmLoadJsView, self).render_to_response(context, **response_kwargs)

        response.content = response.rendered_content.replace(r'\s{2,}', ' ')

        return response

    def get_context_data(self, **kwargs) -> dict:
        context = super(ElmLoadJsView, self).get_context_data(**kwargs)

        context.setdefault('elm', {})
        profile = None

        try:
            profile = self.request.user.student

            context['elm']['student_profile'] = {'quote': False, 'safe': True,
                                                 'value': json.dumps(profile.to_dict())}
            context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                    'value': json.dumps(None)}
        except ObjectDoesNotExist:
            profile = self.request.user.instructor

            context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                    'value': json.dumps(profile.to_dict())}
            context['elm']['student_profile'] = {'quote': False, 'safe': True,
                                                 'value': json.dumps(None)}

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
