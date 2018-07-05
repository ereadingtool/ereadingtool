from django.forms import ModelForm

from text_old.models import Text


class TextForm(ModelForm):
    class Meta:
        model = Text
        fields = ('source', 'difficulty', 'body', 'title', 'author',)
