from typing import AnyStr

from channels.db import database_sync_to_async

from text.consumers.base import TextReaderConsumer
from text_reading.models import StudentTextReading

from text.phrase.models import TextPhrase

from user.models import ReaderUser
from user.student.models import Student


class StudentTextReaderConsumer(TextReaderConsumer):
    def __init__(self, *args, **kwargs):
        super(StudentTextReaderConsumer, self).__init__(*args, **kwargs)

        self.student = None

    @database_sync_to_async
    def start_reading(self):
        # TODO: Why isn't this working? 
        # Warning: potentially breaks reading progress history
        self.student = self.scope['user'].student

        return StudentTextReading.start_or_resume(student=self.student, text=self.text)

    @database_sync_to_async
    def phrase_exists_in_definitions(self, phrase: AnyStr):
        return TextPhrase.objects.filter(text_section=self.text_reading.current_section, phrase=phrase).exists()

    @database_sync_to_async
    def phrase_exists_in_flashcards(self, text_phrase: TextPhrase):
        return self.student.has_flashcard_for_phrase(text_phrase)

    @database_sync_to_async
    def get_text_phrase_in_definitions(self, phrase: AnyStr, instance: int):
        return TextPhrase.objects.filter(text_section=self.text_reading.current_section,
                                         phrase=phrase,
                                         instance=instance).get()

    @database_sync_to_async
    def add_phrase_to_flashcards(self, text_phrase: TextPhrase):
        self.student.add_to_flashcards(text_phrase)

    @database_sync_to_async
    def remove_phrase_from_flashcards(self, text_phrase: TextPhrase):
        self.student.remove_from_flashcards(text_phrase)

    @database_sync_to_async
    def get_flashcards_for_student(self, student: Student):
        return student.flashcards

    async def add_flashcard_phrase(self, user: ReaderUser, phrase: AnyStr, instance: int):
        await super(StudentTextReaderConsumer, self).add_flashcard_phrase(user, phrase, instance)

        if self.student and self.text_reading:
            if await self.phrase_exists_in_definitions(phrase):
                text_phrase = None

                try:
                    text_phrase = await self.get_text_phrase_in_definitions(phrase, instance)
                except TextPhrase.DoesNotExist:
                    await self.send_json({
                        'command': 'exception',
                        'result': {'code': 'unknown', 'error_msg': f'{phrase} does not exist in your text.'}
                    })

                await self.add_phrase_to_flashcards(text_phrase)

                await self.send_json({
                    'command': 'add_flashcard_phrase',
                    'result': await database_sync_to_async(text_phrase.child_instance.to_text_reading_dict)()
                })

    async def remove_flashcard_phrase(self, user: ReaderUser, phrase: AnyStr, instance: int):
        await super(StudentTextReaderConsumer, self).remove_flashcard_phrase(user, phrase, instance)

        if self.student and self.text_reading:
            text_phrase = None

            try:
                text_phrase = await self.get_text_phrase_in_definitions(phrase, instance)
            except TextPhrase.DoesNotExist:
                await self.send_json({
                    'command': 'exception',
                    'result': {'code': 'unknown', 'error_msg': f'{phrase} does not exist in your text.'}
                })

            if await self.phrase_exists_in_flashcards(text_phrase):
                await self.remove_phrase_from_flashcards(text_phrase)

                await self.send_json({
                    'command': 'remove_flashcard_phrase',
                    'result': await database_sync_to_async(text_phrase.child_instance.to_text_reading_dict)()
                })
