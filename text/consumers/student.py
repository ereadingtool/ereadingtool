from channels.db import database_sync_to_async

from text.consumers.base import TextReaderConsumer
from text_reading.models import StudentTextReading


class StudentTextReaderConsumer(TextReaderConsumer):
    def start_reading(self):
        student = self.scope['user'].student

        return database_sync_to_async(StudentTextReading.start_or_resume)(student=student, text=self.text)
