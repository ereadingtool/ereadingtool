import random
import asyncio

from typing import Dict, AnyStr, List, Tuple

from asynctest import TestCase
from channels.testing import WebsocketCommunicator
from channels.db import database_sync_to_async

from ereadingtool.routing import application
from text.tests import TestText, TextSection
from question.models import Answer

from django.test.client import Client


class TestTextReading(TestCase):
    text = None
    student_clients = None

    @classmethod
    def setUpClass(cls):
        test_text_suite = TestText()
        test_text_suite.setUp()

        def rand_question_params():
            return [test_text_suite.gen_text_section_question_params(order=i) for i in range(0, random.randint(0, 3))]

        section_params = [test_text_suite.gen_text_section_params(order=i, question_params=rand_question_params())
                          for i in range(0, random.randint(0, 10))]

        text_params = test_text_suite.get_test_data(section_params=section_params)

        print(f'created {len(section_params)+1} test sections..')

        cls.text = test_text_suite.test_post_text(test_data=text_params)
        cls.num_of_sections = cls.text.sections.count()

        cls.student_clients = [test_text_suite.new_student_client(Client()) for _ in range(0, random.randint(3, 10))]

        print(f'created {len(cls.student_clients)} test student clients')

    def not_state(self, resp: Dict, state_name: AnyStr) -> bool:
        self.assertIn('command', resp)

        return resp['command'] != state_name

    def check_for_intro(self, resp: Dict):
        self.assertIn('command', resp)
        self.assertIn('result', resp)

        self.assertEquals(resp['command'], 'intro')
        self.assertEquals(resp['result'], self.text.to_text_reading_dict())

    def check_complete_scores(self, resp: Dict, correct_answers: int):
        self.assertEquals(resp['result']['complete_sections'], self.num_of_sections)
        self.assertEquals(resp['result']['num_of_sections'], self.num_of_sections)

        # self.assertEquals(resp['result']['section_scores'], correct_answers)

    async def to_next(self, communicator: WebsocketCommunicator) -> Dict:
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)

        if self.not_state(resp, 'complete'):
            self.assertEquals(resp['result'], self.text.sections.all()[resp['result']['order']].to_text_reading_dict(
                num_of_sections=self.num_of_sections))

        return resp

    async def to_prev(self, communicator: WebsocketCommunicator) -> Dict:
        await communicator.send_json_to(data={'command': 'prev'})

        resp = await communicator.receive_json_from()

        return resp

    async def answer(self, communicator: WebsocketCommunicator, answer: Answer) -> Dict:
        await communicator.send_json_to(data={'command': 'answer', 'answer_id': answer.pk})

        resp = await communicator.receive_json_from()

        return resp

    def check_questions(self, resp: Dict):
        self.assertIn('questions', resp['result'])

        # test we're not giving the client the answers
        self.assertNotIn('correct', resp['result']['questions'][0]['answers'][0])

    def choose_random_answer(self, answers: List[Answer]) -> Answer:
        return answers[random.randint(0, len(answers)-1)]

    async def complete_section(self, communicator: WebsocketCommunicator, section: TextSection) -> Tuple[Dict, int]:
        resp = None
        correct_answers = 0

        questions = await database_sync_to_async(section.questions.all)()

        for question in questions:
            all_answers = await database_sync_to_async(question.answers.all)()

            # random number of answer attempts
            answers = [self.choose_random_answer(all_answers) for _ in range(0, random.randint(1, 3))]

            if answers[0].correct:
                correct_answers += 1

            for answer in answers:
                resp = await self.answer(communicator, answer)

        return resp, correct_answers

    async def complete_reading(self, resp: Dict, communicator: WebsocketCommunicator) -> Tuple[Dict, int]:
        num_of_correct_answers = 0
        # ensure we're starting at the beginning
        self.check_for_intro(resp)

        # first section
        resp = await self.to_next(communicator)

        while self.not_state(resp, 'complete'):
            current_section = await database_sync_to_async(self.text.sections.get)(order=resp['result']['order'])

            _, correct_answers = await self.complete_section(communicator, current_section)

            num_of_correct_answers += correct_answers

            resp = await self.to_next(communicator)

        return resp, num_of_correct_answers

    async def test_multiple_student_clients(self):
        print(f'testing {len(self.student_clients)} student clients simultaneously')

        tasks = [self.run_test_student(student_client, i) for i, student_client in enumerate(self.student_clients)]

        await asyncio.gather(*tasks)

    async def run_test_student(self, student_client: Client, student_number: int):
        headers = dict()

        # to pass origin validation
        headers[b'origin'] = b'https://0.0.0.0'

        # to pass authentication, copy the cookies from the test student client
        headers[b'cookie'] = student_client.cookies.output(header='', sep='; ').encode('utf-8')

        communicator = WebsocketCommunicator(application, f'/student/text_read/{self.text.pk}/',
                                             headers=[(k, v) for k, v in headers.items()])

        await self.run_text_reader_consumer(communicator, student_number)

    async def run_text_reader_consumer(self, communicator: WebsocketCommunicator, student_number: int):
        connected, subprotocol = await communicator.connect()

        # start
        self.assertTrue(connected, 'connected')

        resp = await communicator.receive_json_from()

        self.check_for_intro(resp)

        print(f'student {student_number} going to next..')
        resp = await self.to_next(communicator)

        print(f'checking questions for student {student_number}..')
        self.check_questions(resp)

        # go back
        print(f'student {student_number} clicked back')
        resp = await self.to_prev(communicator)

        # back to 'start'
        self.check_for_intro(resp)

        # fill out all text reading answers
        print(f'student {student_number} filled out answers..')
        resp, correct_answers = await self.complete_reading(resp, communicator)

        self.check_complete_scores(resp, correct_answers)

        await communicator.disconnect()
