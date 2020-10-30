from typing import Dict

from csp.decorators import csp_replace
from django.conf import settings
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponseRedirect
from django.urls import reverse
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from user.instructor.models import Instructor
from user.student.models import Student
from auth.normal_auth import jwt_valid


class FlashcardView(LoginRequiredMixin, TemplateView):
    template_name = 'flashcards.html'

    @property
    def model(self):
        raise NotImplementedError

    # since websockets are not the same origin as the HTTP requests (https://github.com/w3c/webappsec/issues/489)
    @csp_replace(CONNECT_SRC=("ws://*" if settings.DEV else "wss://*", "'self'"))
    def dispatch(self, request, *args, **kwargs):
        return super(FlashcardView, self).dispatch(request, *args, **kwargs)

    @jwt_valid(403, {})
    def get(self, request, *args, **kwargs):
        if not isinstance(request.user.profile, self.model):
            return HttpResponseRedirect(reverse('error-page'))

        return super(FlashcardView, self).get(request, *args, **kwargs)


class StudentFlashcardView(FlashcardView):
    model = Student
    login_url = Student.login_url


class InstructorFlashcardView(FlashcardView):
    model = Instructor
    login_url = Instructor.login_url


class FlashcardsLoadElm(ElmLoadJsView):
    template_name = "load_elm.html"

    def get_context_data(self, **kwargs) -> Dict:
        context = super(FlashcardsLoadElm, self).get_context_data(**kwargs)

        host = self.request.get_host()

        profile = self.request.user.profile

        profile_type = profile.__class__.__name__.lower()

        context['elm']['profile_id'] = {'quote': False, 'safe': True, 'value': profile.pk}

        scheme = "ws://" if settings.DEV else "wss://"

        ws_addr = f'{scheme}{host}/{profile_type}/flashcards/'

        context['elm']['flashcard_ws_addr'] = {'quote': True, 'safe': True, 'value': ws_addr}

        return context
