import json

import re

from django.test import TestCase

from django.test.client import Client

from django.http.response import HttpResponse, HttpResponseRedirect

from ereadingtool.test.user import TestUser as TestUserBase
from django.urls import reverse
from django.core import mail


class TestUser(TestUserBase, TestCase):
    def setUp(self):
        super(TestUser, self).setUp()

        self.anonymous_client = Client()

        self.student_user, self.student_passwd, self.student_profile = self.new_student()

        self.student_client = self.new_student_client(Client(), user_and_pass=(self.student_user, self.student_passwd))

        self.student_api_endpoint = reverse('api-student', args=[self.student_profile.pk])
        self.password_reset_api_endpoint = reverse('api-password-reset')
        self.password_reset_confirm_api_endpoint = reverse('api-password-reset-confirm')

    def test_set_username(self):
        resp = self.student_client.put(self.student_api_endpoint,
                                       data=json.dumps({'username': '$$$invalid$$$'}), content_type='application/json')

        self.assertTrue(resp)

        resp_content = json.loads(resp.content)

        self.assertEquals(resp.status_code, 400)

        self.assertEquals(list(resp_content.keys()), ['username'])

        resp = self.student_client.put(self.student_api_endpoint,
                                       data=json.dumps({'username': 'newusername14'}), content_type='application/json')

        self.assertTrue(resp)

        self.assertEquals(resp.status_code, 200)

    def test_password_reset(self):
        self.student_client.logout()

        resp = self.anonymous_client.post(self.password_reset_api_endpoint,
                                          data=json.dumps({'email': self.student_user.email}),
                                          content_type='application/json')

        self.assertTrue(resp)

        resp_content = json.loads(resp.content)

        self.assertEquals(resp_content, {'errors': {},
                                         'body': 'An email has been sent to reset your password, '
                                                 'if that e-mail exists in the system.'})

        self.assertEquals(len(mail.outbox), 1)

        email_body = mail.outbox[0].body

        token_re = re.compile(r'.+/user/password_reset/confirm/(?P<uidb64>.+?)/(?P<token>.+?)/',
                              re.IGNORECASE | re.DOTALL)

        matches = token_re.match(email_body)

        self.assertTrue(matches, 'tokens not sent in email')

        uidb64, token = matches.group('uidb64'), matches.group('token')

        self.assertTrue(len(uidb64) > 1 and len(token) > 1)

        redirect_resp = self.anonymous_client.get(reverse('password-reset-confirm',
                                                          kwargs={'uidb64': uidb64, 'token': token}))

        self.assertIsInstance(redirect_resp, HttpResponseRedirect)

        resp = self.anonymous_client.get(reverse('password-reset-confirm', kwargs={'uidb64': uidb64, 'token': token}),
                                         follow=True)

        self.assertIsInstance(resp, HttpResponse)

        self.assertTrue(resp)

        resp = self.anonymous_client.get(reverse('load-elm-unauth-pass-reset-confirm'))

        self.assertTrue(resp)

        valid_link_re = re.compile(r".+validlink:(?P<validlink>.+?),.+", re.IGNORECASE | re.DOTALL)

        valid_link = valid_link_re.match(resp.content.decode('utf-8')).group('validlink')

        self.assertEquals(valid_link, 'true')

        resp = self.anonymous_client.post(self.password_reset_confirm_api_endpoint,
                                          data=json.dumps({
                                           'uidb64': uidb64,
                                           'new_password1': 'a new pass',
                                           'new_password2': 'a new pass'}), content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        self.student_user.refresh_from_db()

        # test new password works
        new_pass = self.student_user.check_password('a new pass')

        self.assertTrue(new_pass)
