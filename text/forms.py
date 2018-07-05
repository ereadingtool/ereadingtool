from django.forms import ModelForm, ValidationError, CharField

from tag.models import Tag
from text.models import Text

from typing import List, AnyStr
from django.utils.translation import ugettext as _


class TagField(CharField):
    def clean(self, value: List[AnyStr]) -> List[Tag]:
        if isinstance(value, list) and not all(map(lambda t: isinstance(t, str), value)):
            raise ValidationError(
                _('not a list of tag name strings'))

        if value:
            for tag_name in value:
                tag, created = Tag.objects.get_or_create(name=tag_name)

                yield tag


class TextForm(ModelForm):
    tags = TagField()

    class Meta:
        model = Text
        fields = ('introduction', 'tags', 'source', 'difficulty', 'title', 'author',)
