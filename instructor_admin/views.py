from django.views.generic import TemplateView
from text.models import Text


class AdminView(TemplateView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'admin.html'
