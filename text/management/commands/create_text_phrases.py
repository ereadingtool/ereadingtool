from typing import AnyStr, List

import pytz

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
            pac_tz = pytz.timezone('America/Los_Angeles')

            def log(msg, msgs: List[AnyStr]) -> List[AnyStr]:
                logger.debug(msg)

                if msgs is not None:
                    msgs.append(msg)

                return msgs

            log_msgs = log(f'Began cron run for collecting translations on '
                           f'{timezone.now().astimezone(pac_tz).isoformat()}.', [])

            total_translated_words = 0

            try:
                for text_section in TextSection.objects.annotate(
                        num_of_words=models.Count('translated_words')).filter(
                        num_of_words=0):
                    if total_translated_words >= options['run_cron']:
                        break

                    text_section_phrases = list(text_section.words)
                    text_section_phrases_count = len(text_section_phrases)

                    logger.debug(
                        f'text section pk: {text_section.pk} has {text_section_phrases_count} phrases.')

                    if text_section_phrases_count + total_translated_words > options['run_cron']:
                        continue

                    _, log_msgs = consumer.text_section_parse_word_definitions({'text_section_pk': text_section.pk},
                                                                               log_msgs=log_msgs)

                    translated_word_count = text_section.translated_words.count()

                    total_translated_words += translated_word_count

                log_msgs = log(f'Finished cron run.  Translated {total_translated_words} words.', log_msgs)

                logger.info("\n".join(log_msgs))
            except Exception:
                logger.exception(msg='Exception')
