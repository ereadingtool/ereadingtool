from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from text.models import Text
from user.views.mixin import ProfileView, ElmLoadJsView


class AdminView(ProfileView, LoginRequiredMixin, TemplateView):
    login_url = reverse_lazy('instructor-login')


class TextAdminView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/admin.html'


class AdminCreateEditQuizView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/create_quiz.html'


class AdminCreateEditElmLoadView(ElmLoadJsView):
    template_name = "instructor_admin/load_elm.html"
