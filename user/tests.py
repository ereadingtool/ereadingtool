import json

from django.test import TestCase

from django.test.client import Client

from ereadingtool.test.user import TestUser as TestUserBase
from django.urls import reverse
from django.core import mail


class TestUser(TestUserBase, TestCase):
    def setUp(self):
        super(TestUser, self).setUp()

        self.anonymous_client = Client()

        self.student_user, self.student_passwd = self.new_user()

        self.student_client = self.new_student_client(Client(), user_and_pass=(self.student_user, self.student_passwd))

        self.password_reset_api_endpoint = reverse('api-password-reset')

    def test_password_reset(self):
        resp = self.anonymous_client.post(self.password_reset_api_endpoint,
                                          data=json.dumps({'email': self.student_user.email}),
                                          content_type='application/json')

        self.assertTrue(resp)

        resp_content = json.loads(resp.content)

        self.assertEquals(resp_content, {'errors': {},
                                         'body': 'An email has been sent to reset your password, '
                                                 'if that e-mail exists in the system.'})

        self.assertEquals(len(mail.outbox), 1)
