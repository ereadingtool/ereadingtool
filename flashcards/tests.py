from django.test import TestCase

from copy import deepcopy

from flashcards.state.models import FlashcardSessionStateMachine

from text.tests import TestText
from text.phrase.models import TextPhrase

from user.student.models import Student


class TestFlashcardStateMachine(TestText, TestCase):
    def setUp(self):
        super(TestFlashcardStateMachine, self).setUp()

        self.test_student = Student.objects.filter()[0]

        test_data = self.get_test_data()

        test_data['text_sections'][0]['body'] = 'заявление неделю'
        test_data['text_sections'][1]['body'] = 'заявление неделю'

        self.test_run_definition_background_job(test_data)

        text_phrase = TextPhrase.objects.get(phrase='заявление')

        self.test_flashcard = self.test_student.add_to_flashcards(text_phrase)

    def test_review_and_answer_transitions(self):
        state_machine = FlashcardSessionStateMachine(current_flashcard=self.test_flashcard)

        self.assertEquals([tr.target.identifier for tr in state_machine.allowed_transitions], ['choose_mode',
                                                                                               'start_review',
                                                                                               'start_review_and_answer'
                                                                                               ])

        state_machine.start_review_and_answer()

        # internal states
        self.assertEquals([tr.target.identifier for tr in state_machine.allowed_transitions],
                          ['_answered_card_correctly', '_answered_card_incorrectly'])

        old_state_machine = deepcopy(state_machine)

        state_machine.answer_card('stuff')

        self.assertEquals(state_machine.current_state, state_machine.incorrectly_answered_card)

        state_machine = old_state_machine

        state_machine.answer_card('statement')

        self.assertEquals(state_machine.current_state, state_machine.correctly_answered_card)
