from django.core.management.base import BaseCommand
from django.db.models import Count

from text.models import TextSection


class Command(BaseCommand):
    help = 'Lists texts and statistics on their translations.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--notranslations',
            action='store_true',
            dest='notranslations',
            help='Lists only texts with 0 defined words or no translations.',
        )

        parser.add_argument(
            '--translations',
            action='store_true',
            dest='translations',
            help='Lists only texts with translations.',
        )

    def handle(self, *args, **options):
        table_str = '{:<15} {:<15} {:<15} {:>15}'

        columns = table_str.format('text_section_pk', 'text pk', 'num of words', 'num of defined words')

        self.stdout.write(self.style.SUCCESS(columns))

        queryset = TextSection.objects.annotate(num_of_words=Count('translated_words'))

        if options['notranslations']:
            queryset = queryset.filter(num_of_words=0)

        if options['translations']:
            queryset = queryset.annotate(
                translations_count=Count('translated_words__translations')).filter(translations_count__gt=0)

        for section in queryset.filter():
            words = list(section.words)
            num_of_translated_words = section.translated_words.count()

            self.stdout.write(
                self.style.SUCCESS(table_str.format(section.pk, section.text.pk, len(words), num_of_translated_words))
            )
