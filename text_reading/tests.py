
from asynctest import TestCase
from channels.testing import WebsocketCommunicator

from ereadingtool.routing import application
from text.tests import TextTest


class TestTextReading(TestCase):
    text = None
    student_client = None

    @classmethod
    def setUpClass(cls):
        test_text_suite = TextTest()
        test_text_suite.setUp()

        cls.text = test_text_suite.test_post_text()

        cls.student_client = test_text_suite.student

    async def test_text_reader_consumer(self):
        headers = dict()

        # to pass origin validation
        headers[b'origin'] = b'https://0.0.0.0'

        # to pass authentication, copy the cookies from the test student client
        headers[b'cookie'] = self.student_client.cookies.output(header='', sep='; ').encode('utf-8')

        communicator = WebsocketCommunicator(application, f'text_read/{self.text.pk}/',
                                             headers=[(k, v) for k, v in headers.items()])

        connected, subprotocol = await communicator.connect()

        # start
        self.assertTrue(connected, 'connected')

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)

        self.assertEquals(resp['command'], 'intro')
        self.assertEquals(resp['result'], self.text.to_text_reading_dict())

        # proceed to the next step
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)

        num_of_sections = self.text.sections.count()

        self.assertEquals(resp['result'], self.text.sections.all()[0].to_text_reading_dict(
            num_of_sections=num_of_sections))

        # test we're not giving the client the answers
        self.assertIn('questions', resp['result'])

        self.assertNotIn('correct', resp['result']['questions'][0]['answers'][0])

        # test go to prev section
        await communicator.send_json_to(data={'command': 'prev'})

        resp = await communicator.receive_json_from()

        # back to 'start'
        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'intro')
        self.assertIn('result', resp)

        self.assertEquals(resp['result'], self.text.to_text_reading_dict())

        # go back to next section and answer
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'in_progress')
        self.assertIn('result', resp)

        current_section = self.text.sections.get(order=resp['result']['order'])

        current_questions = current_section.questions.all()

        # answer the first question incorrectly
        question_0_answers = current_questions[0].answers.all()

        incorrect_answer = question_0_answers[0] if not question_0_answers[0].correct else question_0_answers[1]

        await communicator.send_json_to(data={'command': 'answer', 'answer_id': incorrect_answer.pk})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'in_progress')
        self.assertIn('result', resp)

        # next section
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'in_progress')
        self.assertIn('result', resp)

        # answer correctly for section 2
        current_section = self.text.sections.get(order=resp['result']['order'])

        current_questions = current_section.questions.all()

        question_0_answers = current_questions[0].answers.all()

        correct_answer = question_0_answers[0]

        if not correct_answer.correct:
            for answer in question_0_answers:
                if answer.correct:
                    correct_answer = answer
                    break

        await communicator.send_json_to(data={'command': 'answer', 'answer_id': correct_answer.pk})

        _ = await communicator.receive_json_from()

        # throw in another incorrect answer (displaying feedback)
        incorrect_answer_two = current_questions[0].answers.exclude(id=correct_answer.pk).filter()[0]

        await communicator.send_json_to(data={'command': 'answer', 'answer_id': incorrect_answer_two.pk})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'in_progress')
        self.assertIn('result', resp)

        # next section
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'complete')
        self.assertIn('result', resp)

        # test scores
        self.assertDictEqual(resp['result'], {
            'complete_sections': num_of_sections,
            'num_of_sections': num_of_sections,
            'possible_section_scores': num_of_sections * sum([section.questions.count()
                                                              for section in self.text.sections.all()]),
            'section_scores': 1
        })

        await communicator.disconnect()
