
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

        self.assertTrue(connected, 'connected')

        await communicator.send_json_to(data={'command': 'start'})

        resp = await communicator.receive_json_from()

        self.assertIn('started', resp)

        # test can't get section information when you haven't started the reading yet
        await communicator.send_json_to(data={'command': 'current_section'})

        resp = await communicator.receive_json_from()

        self.assertIn('error', resp)
        self.assertIn('code', resp['error'])
        self.assertEquals('invalid_state', resp['error']['code'])

        # proceed to the next step
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('next', resp)
        self.assertTrue(resp['next'])

        # test we're not giving the client the answers
        await communicator.send_json_to(data={'command': 'current_section'})

        resp = await communicator.receive_json_from()

        self.assertIn('questions', resp)

        self.assertNotIn('correct', resp['questions'][0]['answers'][0])

        await communicator.disconnect()
