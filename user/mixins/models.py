from logging import raiseExceptions
from typing import AnyStr, Union, Tuple
from typing import Optional

from django.db import models
from django.utils import timezone

from text.models import Text, TextRating
from text_reading.base import TextReadingStateMachine


TextReading = Union['StudentTextReading', 'InstructorTextReading']


class URIs(models.Model):
    class Meta:
        abstract = True

    @classmethod
    def login_url(cls) -> AnyStr:
        raise NotImplementedError


class Profile(URIs):
    class Meta:
        abstract = True

    @classmethod
    def login_url(cls) -> AnyStr:
        raise NotImplementedError

    @property
    def flashcards(self):
        raise NotImplementedError

    @property
    def serialized_flashcards(self):
        raise NotImplementedError


class TextReadings(models.Model):
    class Meta:
        abstract = True

    text_readings = None

    def last_read_dt(self, text: Text) -> Optional[timezone.datetime]:
        last_read_dt = None

        last_reading = self.last_read(text)

        if last_reading and last_reading.last_read_dt:
            last_read_dt = last_reading.last_read_dt.isoformat()

        return last_read_dt

    def last_read_questions_correct(self, text: Text) -> Optional[Tuple[int, int]]:
        last_read = self.last_read(text)

        if not last_read:
            return None
        else:
            last_read_score = last_read.score

            return last_read_score['section_scores'], last_read.max_score

    def last_read(self, text: Text) -> TextReading:
        last_read = None

        # They've got an in progress text
        if self.text_readings \
               .filter(state=TextReadingStateMachine.in_progress.name, text=text) \
               .exists():

            last_read = self.text_readings \
                            .filter(state=TextReadingStateMachine.in_progress.name, text=text) \
                            .get(text=text)

        elif self.text_readings \
                 .filter(state=TextReadingStateMachine.complete.name, text=text) \
                 .exists():

            last_read = self.text_readings \
                            .filter(state=TextReadingStateMachine.complete.name, text=text) \
                            .order_by('-start_dt') \
                            .first()

        return last_read

    def sections_complete_for(self, text: Text) -> int:
        sections_complete = 0
    
        # They have a text inprogress
        if self.text_readings \
               .filter(state=TextReadingStateMachine.in_progress.name, text=text) \
               .exists():

            current_text_reading = self.text_readings \
                                       .filter(state=TextReadingStateMachine.in_progress.name, text=text) \
                                       .get(text=text)

            sections_complete = current_text_reading.current_section.order

        # They've completed the text but haven't started over
        elif self.text_readings \
                 .filter(state=TextReadingStateMachine.complete.name, text=text) \
                 .exists():

            sections_complete = self.text_readings \
                                    .filter(state=TextReadingStateMachine.complete.name, text=text) \
                                    .order_by('start_dt') \
                                    .first() \
                                    .number_of_sections

        return sections_complete

    def vote_history(self, text: Text) -> str:
        try:
            v = TextRating.objects \
                          .filter(text_id=text.id) \
                          .first() \
                          .vote
            if v == 1:
                return "up"
            elif v == 0:
                raise ValueError
            else:
                return "down"

        except:
            # they haven't voted on this text
            return "none"