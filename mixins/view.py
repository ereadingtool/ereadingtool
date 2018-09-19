import json
from typing import Dict

from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import ObjectDoesNotExist
from django.views.decorators.vary import vary_on_cookie
from django.views.generic import TemplateView
from rjsmin import jsmin

from text.models import TextDifficulty


class ElmLoadJsBaseView(TemplateView):
    template_name = "load_elm_base.html"

    # @cache_control(private=True, must_revalidate=True)
    @vary_on_cookie
    def dispatch(self, request, *args, **kwargs):
        return super(ElmLoadJsBaseView, self).dispatch(request, *args, **kwargs)

    # minify js
    def render_to_response(self, context, **response_kwargs):
        response = super(ElmLoadJsBaseView, self).render_to_response(context, **response_kwargs)

        response.render()

        response.content = jsmin(response.content.decode('utf8'))

        return response

    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsBaseView, self).get_context_data(**kwargs)

        context.setdefault('elm', {})

        return context


class ElmLoadJsInstructorView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsInstructorView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.instructor
        except ObjectDoesNotExist:
            pass

        context['elm']['instructor_profile'] = {'quote': False, 'safe': True, 'value': profile or 'null'}

        return context


class ElmLoadJsStudentView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsStudentView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.student
        except ObjectDoesNotExist:
            pass

        context['elm']['student_profile'] = {'quote': False, 'safe': True, 'value': profile or 'null'}

        return context


class ElmLoadJsView(LoginRequiredMixin, ElmLoadJsBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsView, self).get_context_data(**kwargs)

        profile = None

        try:
            profile = self.request.user.student

            context['elm']['student_profile'] = {'quote': False, 'safe': True,
                                                 'value': json.dumps(profile.to_dict())}
            context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                    'value': 'null'}
        except ObjectDoesNotExist:
            profile = self.request.user.instructor

            context['elm']['instructor_profile'] = {'quote': False, 'safe': True,
                                                    'value': json.dumps(profile.to_dict())}
            context['elm']['student_profile'] = {'quote': False, 'safe': True,
                                                 'value': 'null'}

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
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadStudentSignUpView, self).get_context_data(**kwargs)

        context['elm']['difficulties'] = {'quote': False, 'safe': True,
                                          'value':
                                              json.dumps([(text_difficulty.slug, text_difficulty.name)
                                                          for text_difficulty in TextDifficulty.objects.all()])}

        return context
