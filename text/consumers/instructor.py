from channels.db import database_sync_to_async

from channels.consumer import SyncConsumer

from text.consumers.base import TextReaderConsumer, get_text_or_error
from text_reading.models import InstructorTextReading
from asgiref.sync import async_to_sync
from user.models import ReaderUser
from text.definitions.models import TextWordMeaning, TextDefinitions, TextWord


class InstructorTextReaderConsumer(TextReaderConsumer):
    def start_reading(self):
        instructor = self.scope['user'].instructor

        return database_sync_to_async(InstructorTextReading.start_or_resume)(instructor=instructor, text=self.text)


class ParseTextForDefinitions(SyncConsumer):
    def text_parse_word_definitions(self, text_id: int, user: ReaderUser):
        text = async_to_sync(get_text_or_error)(text_id=text_id, user=user)

        word_defs, word_freqs = text.parse_for_definitions()

