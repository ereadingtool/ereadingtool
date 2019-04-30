from django.test import TestCase

from copy import deepcopy

from django.utils import timezone

from flashcards.state.models import FlashcardSessionStateMachine

from ereadingtool.test.user import TestUser
from ereadingtool.test.data import TestData

from text.tests import TestText

from text.translations.models import TextWord
from text.phrase.models import TextPhrase, TextPhraseTranslation
from django.test.client import Client


from user.student.models import Student


class TestFlashcardStateMachine(TestData, TestUser, TestCase):
    def setUp(self):
        super(TestFlashcardStateMachine, self).setUp()

        self.instructor = self.new_instructor_client(Client())
        self.student = self.new_student_client(Client())

        self.text_test = TestText()

        self.text_test.instructor = self.instructor
        self.text_test.student = self.student

        self.test_student = Student.objects.filter()[0]

        test_data = self.get_test_data()

        test_data['text_sections'][0]['body'] = 'заявление неделю Число'
        test_data['text_sections'][1]['body'] = 'заявление неделю стрельбы вещи'

        self.text = self.text_test.test_post_text(test_data=test_data)

        text_sections = self.text.sections.all()

        self.text_phrases = []

        TextPhraseTranslation.create(
            text_phrase=TextWord.create(phrase='заявление', instance=0, text_section=text_sections[0].pk),
            phrase='statement',
            correct_for_context=True
        )

        TextPhraseTranslation.create(
            text_phrase=TextWord.create(phrase='неделю', instance=0, text_section=text_sections[0].pk),
            phrase='week',
            correct_for_context=True
        )

        TextPhraseTranslation.create(
            text_phrase=TextWord.create(phrase='стрельбы', instance=0, text_section=text_sections[1].pk),
            phrase='shooting',
            correct_for_context=True
        )

        TextPhraseTranslation.create(
            text_phrase=TextWord.create(phrase='Число', instance=0, text_section=text_sections[0].pk),
            phrase='number',
            correct_for_context=True
        )

        TextPhraseTranslation.create(
            text_phrase=TextWord.create(phrase='вещи', instance=0, text_section=text_sections[1].pk),
            phrase='number',
            correct_for_context=True
        )

        self.text_phrases.append(TextPhrase.objects.get(phrase='заявление'))
        self.text_phrases.append(TextPhrase.objects.get(phrase='неделю'))
        self.text_phrases.append(TextPhrase.objects.get(phrase='стрельбы'))
        self.text_phrases.append(TextPhrase.objects.get(phrase='Число'))
        self.text_phrases.append(TextPhrase.objects.get(phrase='вещи'))

        self.test_flashcards = []

        self.test_flashcards.append(self.test_student.add_to_flashcards(self.text_phrases[0]))
        self.test_flashcards.append(self.test_student.add_to_flashcards(self.text_phrases[1]))

        self.test_flashcards.append(self.test_student.add_to_flashcards(self.text_phrases[2]))
        self.test_flashcards.append(self.test_student.add_to_flashcards(self.text_phrases[3]))
        self.test_flashcards.append(self.test_student.add_to_flashcards(self.text_phrases[4]))

    def test_flashcard_review_and_answer(self):
        today = timezone.now()

        # test_flashcards[3] has been read once before, and is due to be re-read
        self.test_flashcards[3].repetitions = 1
        self.test_flashcards[3].next_review_dt = today - timezone.timedelta(days=3)

        self.test_flashcards[3].save()

        # test_flashcards[1] has been read twice, and is not due to be re-read
        self.test_flashcards[1].repetitions = 2
        self.test_flashcards[1].next_review_dt = today + timezone.timedelta(days=3)

        self.test_flashcards[1].save()

        state_machine = FlashcardSessionStateMachine(mode='review_and_answer',
                                                     flashcards_queryset=self.test_student.flashcards)

        state_machine.start()

        self.assertEquals(state_machine.current_flashcard, self.test_flashcards[0])

        state_machine.answer_card(state_machine.translation_for_current_flashcard.phrase)

        self.assertEquals(state_machine.current_state, state_machine.correctly_answered_card)

        state_machine.rate_quality(3)
        state_machine.next()

        self.assertEquals(state_machine.current_flashcard, self.test_flashcards[2])

        state_machine.answer_card(state_machine.translation_for_current_flashcard.phrase)

        self.assertEquals(state_machine.current_state, state_machine.correctly_answered_card)

        state_machine.rate_quality(3)
        state_machine.next()

        self.assertEquals(state_machine.current_flashcard, self.test_flashcards[4])

        state_machine.answer_card(state_machine.translation_for_current_flashcard.phrase)

        self.assertEquals(state_machine.current_state, state_machine.correctly_answered_card)

        state_machine.rate_quality(3)
        state_machine.next()

        self.assertEquals(state_machine.current_flashcard, self.test_flashcards[3])

        state_machine.answer_card(state_machine.translation_for_current_flashcard.phrase)

        self.assertEquals(state_machine.current_state, state_machine.correctly_answered_card)

        state_machine.rate_quality(3)
        state_machine.next()

        self.assertEquals(state_machine.current_state, state_machine.finished_review_and_answer)

        # tweaking SM-2 leads to different review dates so we just check the year for sanity + repetitions
        self.assertEquals(
            [[c.next_review_dt.year, c.repetitions]
             for c in self.test_student.flashcards.all()], [
                [2019, self.test_flashcards[0].repetitions+1],
                [2019, self.test_flashcards[1].repetitions],  # not due for review
                [2019, self.test_flashcards[2].repetitions+1],
                [2019, self.test_flashcards[3].repetitions+1],
                [2019, self.test_flashcards[4].repetitions+1]])

    def test_review_and_answer_transitions(self):
        state_machine = FlashcardSessionStateMachine(mode='review_and_answer',
                                                     flashcards_queryset=self.test_student.flashcards)

        self.assertEquals(state_machine.current_flashcard, self.test_flashcards[0])

        self.assertEquals([tr.target.identifier for tr in state_machine.allowed_transitions], [
            'choose_mode',
            '_start_review',
            '_start_review_and_answer'
        ])

        state_machine.start()

        # internal states
        self.assertEquals([tr.target.identifier for tr in state_machine.allowed_transitions],
                          ['_answered_card_correctly', '_answered_card_incorrectly'])

        old_state_machine = deepcopy(state_machine)

        state_machine.answer_card('stuff')

        self.assertEquals(state_machine.current_state, state_machine.incorrectly_answered_card)

        state_machine = old_state_machine

        state_machine.answer_card('statement')

        self.assertEquals(state_machine.current_state, state_machine.correctly_answered_card)
