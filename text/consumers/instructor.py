import logging

from typing import Dict

from django.db import transaction

from lxml.html import fragment_fromstring
from lxml.html.diff import htmldiff

from channels.db import database_sync_to_async

from channels.consumer import SyncConsumer

from text.consumers.base import TextReaderConsumer
from text_reading.models import InstructorTextReading
from text.models import TextSection

from text.definitions.models import TextWordTranslation, TextWord

logger = logging.getLogger('django.consumers')


class InstructorTextReaderConsumer(TextReaderConsumer):
    def start_reading(self):
        instructor = self.scope['user'].instructor

        return database_sync_to_async(InstructorTextReading.start_or_resume)(instructor=instructor, text=self.text)


class ParseTextSectionForDefinitions(SyncConsumer):
    def text_section_update_definitions_if_new(self, message: Dict):
        text_section = TextSection.objects.get(pk=message['text_section_pk'])

        old_html = fragment_fromstring(message['old_body'], create_parent='div')
        new_html = fragment_fromstring(text_section.body, create_parent='div')

        if htmldiff(old_html, new_html):
            logger.info(f'Found new body in text section pk={message["text_section_pk"]}')

            text_section.update_definitions()

    def text_section_parse_word_definitions(self, message: Dict):
        text_section = TextSection.objects.get(pk=message['text_section_pk'])

        text_section_words = list(text_section.words)

        logger.info(f'Parsing {len(text_section_words)} word definitions '
                    f'for text section pk={message["text_section_pk"]}')

        word_data, word_freqs = text_section.parse_word_definitions()

        for word in word_data:
            for i, word_instance in enumerate(word_data[word]):
                with transaction.atomic():
                    text_word, text_word_created = TextWord.objects.get_or_create(
                        text=text_section.text,
                        word=word,
                        instance=i,
                        **word_instance['grammemes'])

                    if text_word_created:
                        # populate translations
                        logger.info(f'created a new word "{text_word.word}" '
                                    f'(pk: {text_word.pk}, instance: {text_word.instance}) '
                                    f'for section pk {text_section.pk}')

                        text_word.save()

                        if len(word_instance['translations']):
                            for j, translation in enumerate(word_instance['translations']):
                                if translation.phrase:
                                    text_word_definition = TextWordTranslation.objects.create(
                                        word=text_word,
                                        phrase=translation.phrase.text,
                                        correct_for_context=(True if j == 0 else False))

                                    text_word_definition.save()

                            logger.info(f'created '
                                        f'{len(word_instance["translations"])} translations '
                                        f'for text word pk {text_word.pk}')

        logger.info(f'Finished parsing translations for text section pk={message["text_section_pk"]}')

        text_section.save()

        return text_section
