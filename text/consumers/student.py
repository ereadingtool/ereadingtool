from typing import AnyStr

from channels.db import database_sync_to_async

from text.consumers.base import TextReaderConsumer
from text_reading.models import StudentTextReading

from text.definitions.models import TextWord

from user.models import ReaderUser
from user.student.models import Student
from flashcards.models import Flashcards


class StudentTextReaderConsumer(TextReaderConsumer):
    def __init__(self, *args, **kwargs):
        super(StudentTextReaderConsumer, self).__init__(*args, **kwargs)

        self.student = None

    @database_sync_to_async
    def start_reading(self):
        self.student = self.scope['user'].student

        return StudentTextReading.start_or_resume(student=self.student, text=self.text)

    @database_sync_to_async
    def word_exists_in_definitions(self, word: AnyStr):
        return TextWord.objects.filter(text_section=self.text_reading.current_section, word=word).exists()

    @database_sync_to_async
    def word_exists_in_flashcards(self, flashcards: Flashcards, text_word: TextWord):
        return flashcards.words.filter(pk=text_word.pk).exists()

    @database_sync_to_async
    def get_word_in_definitions(self, word: AnyStr, instance: int):
        return TextWord.objects.filter(text_section=self.text_reading.current_section,
                                       word=word,
                                       instance=instance).get()

    @database_sync_to_async
    def add_word_to_flashcards(self, flashcards: Flashcards, text_word: TextWord):
        flashcards.words.add(text_word)
        flashcards.save()

    @database_sync_to_async
    def remove_word_from_flashcards(self, flashcards: Flashcards, text_word: TextWord):
        flashcards.words.remove(text_word)

    @database_sync_to_async
    def get_flashcards_for_student(self, student: Student):
        if student.flashcards is None:
            flashcards = Flashcards.objects.create()
            flashcards.save()

            student.flashcards = flashcards
            student.save()

            return flashcards
        else:
            return student.flashcards

    async def add_flashcard_word(self, user: ReaderUser, word: AnyStr, instance: int):
        await super(StudentTextReaderConsumer, self).add_flashcard_word(user, word, instance)

        if self.student and self.text_reading:
            if await self.word_exists_in_definitions(word):
                flashcards = await self.get_flashcards_for_student(self.student)

                text_word = None

                try:
                    text_word = await self.get_word_in_definitions(word, instance)
                except TextWord.DoesNotExist:
                    await self.send_json({
                        'command': 'exception',
                        'result': {'code': 'unknown', 'error_msg': f'{word} does not exist in your text.'}
                    })

                await self.add_word_to_flashcards(flashcards, text_word)

                await self.send_json({
                    'command': 'add_flashcard_word',
                    'result': await database_sync_to_async(text_word.to_dict)()
                })

    async def remove_flashcard_word(self, user: ReaderUser, word: AnyStr, instance: int):
        await super(StudentTextReaderConsumer, self).remove_flashcard_word(user, word, instance)

        if self.student and self.text_reading:
            text_word = None

            try:
                text_word = await self.get_word_in_definitions(word, instance)
            except TextWord.DoesNotExist:
                await self.send_json({
                    'command': 'exception',
                    'result': {'code': 'unknown', 'error_msg': f'{word} does not exist in your text.'}
                })

            if await self.word_exists_in_flashcards(self.student.flashcards, text_word):
                await self.remove_word_from_flashcards(self.student.flashcards, text_word)

                await self.send_json({
                    'command': 'remove_flashcard_word',
                    'result': await database_sync_to_async(text_word.to_dict)()
                })
