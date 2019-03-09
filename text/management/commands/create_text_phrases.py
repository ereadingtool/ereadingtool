import logging

from django.core.management.base import BaseCommand, CommandError

from text.models import TextSection
from text.consumers.instructor import ParseTextSectionForDefinitions

from django.db import models
from django.utils import timezone


logger = logging.getLogger('django.consumers')


class Command(BaseCommand):
    help = 'Collect translations for particular text sections.'

    def add_arguments(self, parser):
        parser.add_argument('--text_section', nargs='?', default=None, action='store',
                            help='Creates TextPhrases for one text section.')

        parser.add_argument('--run-cron', action='store', nargs='?', default=None, type=int,
                            help='Translate a certain amount of text words based on a given limit')

    def handle(self, *args, **options):
        consumer = ParseTextSectionForDefinitions(scope={})

        if options['text_section']:
            try:
                text_section = TextSection.objects.get(pk=options['text_section'])

                consumer.text_section_parse_word_definitions({'text_section_pk': text_section.pk})
            except TextSection.DoesNotExist:
                raise CommandError(f"Can't find text section pk: {options['text_section']}")

        if options['run_cron']:
            logger.info(f'Began cron run for collecting translations.')

            total_translated_words = 0

            try:
                for text_section in TextSection.objects.annotate(
                        num_of_words=models.Count('translated_words')).filter(
                        num_of_words=0):
                    if total_translated_words >= options['run_cron']:
                        break

                    text_section_words = list(text_section.words)

                    if len(text_section_words) + total_translated_words > options['run_cron']:
                        continue

                    consumer.text_section_parse_word_definitions({'text_section_pk': text_section.pk})

                    translated_word_count = text_section.translated_words.count()

                    total_translated_words += translated_word_count

                logger.info(f'Finished cron run.  Translated {total_translated_words} words.')
            except Exception:
                logger.exception(msg='Exception')
