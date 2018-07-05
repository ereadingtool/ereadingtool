from django.apps import AppConfig
from tagging.registry import register


class TextConfig(AppConfig):
    name = 'text_old'

    def ready(self):
        register(self.get_model('Text'), tag_descriptor_attr='themes')
