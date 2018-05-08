import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView
from django.db.models import ObjectDoesNotExist
from text.models import TextDifficulty


class ElmLoadJsBaseView(TemplateView):
    template_name = "load_elm_base.html"

    # minify js
    def render_to_response(self, context, **response_kwargs):
        response = super(ElmLoadJsBaseView, self).render_to_response(context, **response_kwargs)

        response.content = response.rendered_content.replace(r'\s{2,}', ' ')

        return response

    def get_context_data(self, **kwargs) -> dict:
        context = super(ElmLoadJsBaseView, self).get_context_data(**kwargs)

        context.setdefault('elm', {})

        return context


class ElmLoadJsView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> dict:
        context = super(ElmLoadJsBaseView, self).get_context_data(**kwargs)

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


class NoAuthElmLoadJsView(ElmLoadJsBaseView):
    pass


class ElmLoadStudentSignUpView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs) -> dict:
        context = super(ElmLoadStudentSignUpView, self).get_context_data(**kwargs)

        context['elm']['difficulties'] = {'quote': False, 'safe': True,
                                          'value':
                                              json.dumps([(text_difficulty.slug, text_difficulty.name)
                                                          for text_difficulty in TextDifficulty.objects.all()])}

        return context
