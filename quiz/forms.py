from django.forms import ModelForm, ValidationError, CharField

from quiz.models import Quiz
from tag.models import Tag

from typing import List
from django.utils.translation import ugettext as _


class TagField(CharField):
    def clean(self, value: List[str]) -> List[Tag]:

        if not isinstance(value, list):
            raise ValidationError(
                _('not a list of tags'))

        if not all(map(lambda t: isinstance(t, str), value)):
            raise ValidationError(
                _('not a list of tag name strings'))

        for tag_name in value:
            tag, created = Tag.objects.get_or_create(name=tag_name)

            yield tag


class QuizForm(ModelForm):
    class Meta:
        model = Quiz
        fields = ('title', 'introduction', 'tags', )

    tags = TagField()

    def save(self, commit=True):
        quiz = super(QuizForm, self).save(commit=commit)

        return quiz
