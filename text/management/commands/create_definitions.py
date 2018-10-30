from django.core.management.base import BaseCommand, CommandError

from text.models import TextSection
from text.consumers.instructor import ParseTextSectionForDefinitions


class Command(BaseCommand):
    help = 'Collects definitions for all text sections.'

    def add_arguments(self, parser):
        parser.add_argument('text_section', action='store', help='Collects definitions for one text section.')

    def handle(self, *args, **options):
        text_sections = []

        if options['text_section']:
            try:
                text_section = TextSection.objects.get(pk=options['text_section'])
                text_sections.append(text_section)
            except TextSection.DoesNotExist:
                raise CommandError(f"Can't find text section pk: {options['text_section']}")
        else:
            text_sections = TextSection.objects.all()

        consumer = ParseTextSectionForDefinitions(scope={})

        for section in text_sections:
            consumer.text_section_parse_word_definitions({'text_section_pk': section.pk})
