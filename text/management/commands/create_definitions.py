from django.core.management.base import BaseCommand, CommandError

from text.models import TextSection
from text.consumers.instructor import ParseTextSectionForDefinitions


class Command(BaseCommand):
    help = 'Collects definitions for a particular text section.'

    def add_arguments(self, parser):
        parser.add_argument('text_section', action='store', help='Collects definitions for one text section.')

    def handle(self, *args, **options):
        if options['text_section']:
            try:
                text_section = TextSection.objects.get(pk=options['text_section'])
                consumer = ParseTextSectionForDefinitions(scope={})

                consumer.text_section_parse_word_definitions({'text_section_pk': text_section.pk})
            except TextSection.DoesNotExist:
                raise CommandError(f"Can't find text section pk: {options['text_section']}")
