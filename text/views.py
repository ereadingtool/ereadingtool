from django.views.generic.detail import DetailView
from text.models import Text


class TextDetailView(DetailView):
    model = Text
