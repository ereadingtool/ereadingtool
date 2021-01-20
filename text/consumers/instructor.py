import logging

from typing import Dict, AnyStr, List, Tuple, Union

from django.db import transaction

from lxml.html import fragment_fromstring
from lxml.html.diff import htmldiff

from channels.db import database_sync_to_async

from channels.consumer import SyncConsumer

from text.consumers.base import TextReaderConsumer
from text_reading.models import InstructorTextReading
from text.models import TextSection

from text.phrase.models import TextPhraseTranslation
from text.translations.models import TextWord

logger = logging.getLogger('django.consumers')


class InstructorTextReaderConsumer(TextReaderConsumer):
    @database_sync_to_async
    def start_reading(self):
        instructor = self.scope['user'].instructor

        return InstructorTextReading.start_or_resume(instructor=instructor, text=self.text)


class ParseTextSectionForDefinitions(SyncConsumer):
    def text_section_update_definitions_if_new(self, message: Dict):
        text_section = TextSection.objects.get(pk=message['text_section_pk'])

        old_html = fragment_fromstring(message['old_body'], create_parent='div')
        new_html = fragment_fromstring(text_section.body, create_parent='div')

        if htmldiff(old_html, new_html):
            logger.info(f'Found new body in text section pk={message["text_section_pk"]}')

            text_section.update_definitions()

    def text_section_parse_word_definitions(self, message: Dict, *args, log_msgs: List[AnyStr] = None,
                                            **kwargs) -> Tuple[TextSection, List[AnyStr]]:
        text_section = TextSection.objects.get(pk=message['text_section_pk'])

        text_section_words = list(text_section.words)

        def log(msg: AnyStr, msgs: Union[List[AnyStr], None]) -> List[AnyStr]:
            logger.debug(msg)

            if msgs:
                msgs.append(msg)

            return msgs

        log_msgs = log(f'Parsing {len(text_section_words)} word definitions for '
                       f'text section pk={message["text_section_pk"]}', log_msgs)

        word_data, word_freqs = text_section.parse_word_definitions()

        for word in word_data:
            for i, word_instance in enumerate(word_data[word]):
                with transaction.atomic():
                    text_word, text_word_created = TextWord.objects.get_or_create(
                        text_section=text_section,
                        phrase=word,
                        instance=i,
                        **word_instance['grammemes'])

                    if text_word_created:
                        # populate translations
                        log_msgs = log(f'created a new word "{text_word.phrase}" '
                                       f'(pk: {text_word.pk}, instance: {text_word.instance}) '
                                       f'for section pk {text_section.pk}', log_msgs)

                        text_word.save()

                        if len(word_instance['translations']):
                            for j, translation in enumerate(word_instance['translations']):
                                if translation.phrase:
                                    text_word_definition = TextPhraseTranslation.create(
                                        text_phrase=text_word,
                                        phrase=translation.phrase.text,
                                        correct_for_context=(True if j == 0 else False))

                                    text_word_definition.save()

                            log_msgs = log(f'created '
                                           f'{len(word_instance["translations"])} translations '
                                           f'for text word pk {text_word.pk}', log_msgs)

        log_msgs = log(f'Finished parsing translations for text section pk={message["text_section_pk"]}', log_msgs)

        text_section.translation_service_processed = 1

        text_section.save()

        return text_section, log_msgs
