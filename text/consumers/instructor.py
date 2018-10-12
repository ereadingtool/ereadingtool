from channels.db import database_sync_to_async

from channels.consumer import SyncConsumer

from text.consumers.base import TextReaderConsumer
from text_reading.models import InstructorTextReading
from text.models import TextSection

from text.definitions.models import TextWordMeaning, TextDefinitions, TextWord


class InstructorTextReaderConsumer(TextReaderConsumer):
    def start_reading(self):
        instructor = self.scope['user'].instructor

        return database_sync_to_async(InstructorTextReading.start_or_resume)(instructor=instructor, text=self.text)


class ParseTextSectionForDefinitions(SyncConsumer):
    def text_parse_word_definitions(self, text_section_pk: int):
        text_section = TextSection.objects.get(pk=text_section_pk)
        text_section_definitions = text_section.definitions

        if not text_section_definitions:
            text_section_definitions = TextDefinitions.objects.create()
            text_section_definitions.save()

        word_defs, word_freqs = text_section.parse_for_definitions()

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

        return text_section_definitions
