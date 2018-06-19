from typing import List, Union

from django.core.exceptions import ObjectDoesNotExist
from django.db import models

from mixins.model import Timestamped, WriteLockable


class Tag(models.Model):
    name = models.CharField(max_length=128, null=False, db_index=True)

    @classmethod
    def setup_default(cls):
        for default_tag in ['Culture', 'Music', 'Film', 'Literary Arts', 'Visual Arts', 'Sports', 'Politics', 'History',
                            'Biography', 'Current Events', 'Economics/Business', 'Medicine/Health Care',
                            'Science/Technology', 'Human Interest', 'Society and Societal Trends',
                            'Internal Affairs/Foreign Policy', 'Public Policy', 'Other']:
            tag = Tag.objects.create(name=default_tag)
            tag.save()


class Taggable(models.Model):
    class Meta:
        abstract = True

    tags = models.ManyToManyField(Tag, related_name='quizzes')

    def add_tag(self, tag_name: str):
        tag, created = Tag.objects.get_or_create(name=tag_name)

        if created:
            tag.save()

        self.tags.add(tag)

    def add_tags(self, tag_names: Union[List[str], str]):
        if not isinstance(tag_names, list):
            tag_names = [tag_names]

        for tag_name in tag_names:
            self.add_tag(tag_name)

    def remove_tag(self, tag_name: str):
        try:
            tag = Tag.objects.get(name=tag_name)
            self.tags.remove(tag)
        except ObjectDoesNotExist:
            pass

    @classmethod
    def tag_choices(cls):
        return Tag.objects.all()
