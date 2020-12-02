from typing import AnyStr, Union, Tuple
from typing import Optional

from django.db import models
from django.utils import timezone

from text.models import Text
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
    # TODO: questions correct feature is here?
    def last_read_questions_correct(self, text: Text) -> Optional[Tuple[int, int]]:
        last_read = self.last_read(text)

        if not last_read:
            return None
        else:
            last_read_score = last_read.score

            return last_read_score['section_scores'], last_read.max_score

    def last_read(self, text: Text) -> TextReading:
        last_read = None

        if self.text_readings.filter(text=text).exists():
            last_read = self.text_readings.filter(text=text).order_by('-start_dt')[0]

        return last_read

    def sections_complete_for(self, text: Text) -> int:
        """
        Check to see if the user has completed reading a text. If so the ratio of "Sections Complete" is `number_of_sections`/`number_of_sections`.
        Otherwise we look to see if they've attempted it at all (and are beyond the intro step). If so, return the `current_section`. 
        """
        sections_complete = 0

        if self.text_readings \
               .filter(state=TextReadingStateMachine.complete.name, student_id=self.id, text=text) \
               .exists():

            # Get the first completion
            student_text_reading = self.text_readings \
                                       .filter(state=TextReadingStateMachine.complete.name, student_id=self.id, text=text) \
                                       .order_by('start_dt') \
                                       .first()

            sections_complete = student_text_reading.number_of_sections

        elif self.text_readings \
                 .exclude(state=TextReadingStateMachine.complete.name) \
                 .filter(text=text) \
                 .exists():

            current_text_reading = self.text_readings \
                                       .exclude(state=TextReadingStateMachine.complete.name) \
                                       .get(text=text)

            if not current_text_reading.state_machine.is_intro:
                sections_complete = current_text_reading.current_section.order

        return sections_complete
