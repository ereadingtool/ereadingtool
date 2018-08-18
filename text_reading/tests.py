
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

        # test can't go to next step when you haven't started the reading yet
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('error', resp)
        self.assertIn('code', resp['error'])
        self.assertEquals('invalid_state', resp['error']['code'])

        await communicator.send_json_to(data={'command': 'start'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)
        self.assertTrue(resp['result'])

        # proceed to the next step
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)
        self.assertTrue(resp['result'])

        # test we're not giving the client the answers
        await communicator.send_json_to(data={'command': 'current_section'})

        resp = await communicator.receive_json_from()

        self.assertIn('questions', resp)

        self.assertNotIn('correct', resp['questions'][0]['answers'][0])

        # test request of the text information
        await communicator.send_json_to(data={'command': 'text'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)

        self.assertDictEqual(resp['result'], self.text.to_text_reading_dict())

        await communicator.disconnect()
