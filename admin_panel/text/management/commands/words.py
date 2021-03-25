from django.core.management.base import BaseCommand, CommandError
from text.models import TextSection


class Command(BaseCommand):
    help = 'Returns the number of words within a text section.'

    def add_arguments(self, parser):
        parser.add_argument('text_section_id', nargs='+', type=int)

    def handle(self, *args, **options):
        for text_section_id in options['text_section_id']:
            try:
                text_section = TextSection.objects.get(pk=text_section_id)
                words = list(text_section.words)
            except TextSection.DoesNotExist:
                raise CommandError(f'Text section pk={text_section_id} does not exist.')

            self.stdout.write(self.style.SUCCESS(f'Text section pk='
                                                 f'{text_section_id} has {len(words)} words.'))
