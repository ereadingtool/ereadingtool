from typing import AnyStr

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


from flashcards.consumers.exceptions import FlashcardSessionException
from flashcards.state.exceptions import FlashcardStateMachineException, StateMachineError
from flashcards.state.models import FlashcardSessionStateMachine, Mode


class FlashcardSession(models.Model):
    class Meta:
        abstract = True

    state_machine_cls = FlashcardSessionStateMachine

    """
    A model that keeps track of individual flashcard sessions.
    """
    state = models.CharField(max_length=64, null=False, default=state_machine_cls.mode_choice.name)

    mode = models.CharField(max_length=32, choices=((mode.name, mode.value) for mode in list(Mode)),
                            default=Mode.review.name)

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True, blank=True)

    def set_mode(self, mode: AnyStr):
        self.state_machine.set_mode_from_string(mode)

    @property
    def state_name(self) -> AnyStr:
        return self.state_machine.current_state.name

    def serialize(self):
        return self.state_machine.serialize()

    def start(self):
        self.state_machine.start()

    def review(self):
        self.state_machine.review()

    def rate_quality(self, rating: int):
        self.state_machine.rate_quality(rating)

    def on_finish(self):
        self.end_dt = timezone.now()
        self.save()

    def answer(self, answer: AnyStr):
        try:
            self.state_machine.answer_card(answer)
        except FlashcardStateMachineException as e:
            raise FlashcardSessionException(code=e.code, error_msg=e.error_msg)

    def prev(self):
        try:
            self.state_machine.prev()
        except FlashcardStateMachineException as e:
            raise FlashcardSessionException(code=e.code, error_msg=e.error_msg)

        self.save()

    def next(self):
        try:
            self.state_machine.next()
        except FlashcardStateMachineException as e:
            raise FlashcardSessionException(code=e.code, error_msg=e.error_msg)

        self.save()

    @property
    def flashcards(self):
        raise NotImplementedError

    def clean(self):
        try:
            self.state_machine.check()
        except StateMachineError as e:
            raise ValidationError(f'invalid state: {e}')

    def save(self, force_insert=False, force_update=False, using=None, update_fields=None):
        self.state = self.state_machine.current_state.name
        self.mode = self.state_machine.mode.name
        self.current_flashcard = self.state_machine.current_flashcard

        self.full_clean()

        super(FlashcardSession, self).save(force_insert, force_update, using, update_fields)

    def __init__(self, *args, **kwargs):
        """
        Deserialize the state from the db.
        """
        super(FlashcardSession, self).__init__(*args, **kwargs)

        if not self.current_flashcard:
            self.current_flashcard = self.flashcards[0]

        self.state_machine = self.state_machine_cls(state=self.state, mode=self.mode,
                                                    flashcards_queryset=self.flashcards,
                                                    current_flashcard=self.current_flashcard)

        self.state_machine.on_finish = self.on_finish

        self.state_machine.check()
