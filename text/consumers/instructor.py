import logging

from typing import Dict

from lxml.html import fragment_fromstring
from lxml.html.diff import htmldiff

from channels.db import database_sync_to_async

from channels.consumer import SyncConsumer

from text.consumers.base import TextReaderConsumer
from text_reading.models import InstructorTextReading
from text.models import TextSection

from text.definitions.models import TextWordMeaning, TextDefinitions, TextWord

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
        text_section_definitions = text_section.definitions

        if not text_section_definitions:
            text_section_definitions = TextDefinitions.objects.create()
            text_section_definitions.save()

        logger.info(f'Parsing definitions for text section pk={message["text_section_pk"]}')

        word_defs, word_freqs = text_section.parse_word_definitions()

        for word in word_defs:
            text_word = TextWord.objects.create(
                definitions=text_section_definitions,
                normal_form=word,
                **word_defs[word]['grammemes'])

            text_word.save()

            if word_defs[word] is not None:
                for meaning in word_defs[word]['meanings']:
                    text_meaning = TextWordMeaning.objects.create(word=text_word, text=meaning['text'])
                    text_meaning.save()

        logger.info(f'Finished parsing definitions for text section pk={message["text_section_pk"]}')

        return text_section_definitions
