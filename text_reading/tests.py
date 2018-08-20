
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

        self.assertEquals(resp['command'], 'start')
        self.assertEquals(resp['result'], self.text.to_text_reading_dict())

        # proceed to the next step
        await communicator.send_json_to(data={'command': 'next'})

        resp = await communicator.receive_json_from()

        self.assertIn('command', resp)
        self.assertIn('result', resp)

        self.assertEquals(resp['result'], self.text.sections.all()[0].to_text_reading_dict())

        # test we're not giving the client the answers
        self.assertIn('questions', resp['result'])

        self.assertNotIn('correct', resp['result']['questions'][0]['answers'][0])

        # test go to prev section
        await communicator.send_json_to(data={'command': 'prev'})

        resp = await communicator.receive_json_from()

        # back to 'start'
        self.assertIn('command', resp)
        self.assertEquals(resp['command'], 'start')
        self.assertIn('result', resp)

        self.assertEquals(resp['result'], self.text.to_text_reading_dict())

        await communicator.disconnect()
