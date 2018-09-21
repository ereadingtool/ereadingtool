from channels.db import database_sync_to_async

from text.consumers.base import TextReaderConsumer
from text_reading.models import InstructorTextReading


class InstructorTextReaderConsumer(TextReaderConsumer):
    def start_reading(self):
        instructor = self.scope['user'].instructor

        return database_sync_to_async(InstructorTextReading.start_or_resume)(instructor=instructor, text=self.text)
