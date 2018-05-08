from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from text.models import Text
from user.views.mixin import ProfileView
from mixins.view import ElmLoadJsView
from csp.decorators import csp_replace


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

    # for CkEditor, allow exceptions to the CSP rules for unsafe-inline code and styles.
    @csp_replace(STYLE_SRC=("'self'", "'unsafe-inline'",), SCRIPT_SRC=("'self'", "'unsafe-inline'",))
    def dispatch(self, request, *args, **kwargs):
        return super(AdminCreateEditQuizView, self).dispatch(request, *args, **kwargs)


class AdminCreateEditElmLoadView(ElmLoadJsView):
    template_name = "instructor_admin/load_elm.html"
