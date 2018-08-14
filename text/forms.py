from django.forms import ModelForm, ValidationError, CharField

from tag.models import Tag
from text.models import Text, TextSection

from typing import List, AnyStr
from django.utils.translation import ugettext as _


class TagField(CharField):
    def clean(self, value: List[AnyStr]) -> List[Tag]:
        if isinstance(value, list) and not all(map(lambda t: isinstance(t, str), value)):
            raise ValidationError(
                _('not a list of tag name strings'))

        if not value:
            # need at least one tag
            raise ValidationError('Texts requires at least one tag.')
        else:
            for tag_name in value:
                tag, created = Tag.objects.get_or_create(name=tag_name)

                yield tag


class TextForm(ModelForm):
    tags = TagField()

    def __init__(self, *args, **kwargs):
        super(TextForm, self).__init__(*args, **kwargs)

        self.fields['difficulty'].required = False

    class Meta:
        model = Text
        fields = ('introduction', 'conclusion', 'tags', 'source', 'difficulty', 'title', 'author',)


class TextSectionForm(ModelForm):
    def __init__(self, *args, **kwargs):
        super(TextSectionForm, self).__init__(*args, **kwargs)

        self.fields['order'].required = False

    class Meta:
        model = TextSection
        fields = ('body', 'order',)
