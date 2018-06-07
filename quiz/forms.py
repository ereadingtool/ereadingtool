from django.forms import ModelForm, ValidationError, CharField

from quiz.models import Quiz
from typing import List
from django.utils.translation import ugettext as _


class TagField(CharField):
    def clean(self, value: List[str]) -> List[str]:

        if not isinstance(value, list):
            raise ValidationError(
                _("Please provide a list of tag strings"))

        if not all(map(lambda t: isinstance(t, str), value)):
            raise ValidationError(
                _("Please provide a list of tag strings"))

        return value


class QuizForm(ModelForm):
    class Meta:
        model = Quiz
        fields = ('title', 'introduction', 'tags', )

    tags = TagField()

    def save(self, commit=True):
        quiz = super(QuizForm, self).save(commit=True)

        return quiz
