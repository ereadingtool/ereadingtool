import random
import string
import json

from typing import AnyStr, Optional

from django.test import TestCase
from django.test.client import Client

from django.utils import timezone

from django.urls import reverse
from django.http import HttpResponse

from ereadingtool.test.user import TestUser as TestUserBase
from text.models import TextDifficulty

from invite.models import Invite


class TestInstructorUser(TestUserBase, TestCase):
    def setUp(self):
        super(TestInstructorUser, self).setUp()

        TextDifficulty.setup_default()

        self.setup_admin_instructor()

        self.invite_endpoint = reverse('api-instructor-invite')

    def invite(self, client: Client, invitee_email: AnyStr) -> HttpResponse:
        return client.post(self.invite_endpoint, data=json.dumps({
            'email': invitee_email,
        }), content_type='application/json')

    def instructor_signup(self, invite_code: AnyStr, email: AnyStr,
                          password: Optional[AnyStr] = None) -> HttpResponse:
        password = password or ''.join(random.choices(
            string.ascii_uppercase + string.digits + string.ascii_lowercase, k=8))

        anonymous_client = Client()

        resp = anonymous_client.post(reverse('api-instructor-signup'), data=json.dumps({
            'email': email,
            'password': password,
            'confirm_password': password,
            'invite_code': invite_code
        }), content_type='application/json')

        return resp

    def setup_admin_instructor(self):
        self.instructor_admin_user, self.instructor_admin_password = self.new_user(
            username='ereader@pdx.edu',
            password='test-p4ssw0rd!'
        )

        admin_instructor = self.new_instructor_with_user(self.instructor_admin_user, admin=True)

        self.assertTrue(admin_instructor.is_admin)

    def test_other_users_cant_invite(self):
        invitee_email = 'test-invite@test.com'

        # no anonymous users
        resp = self.invite(Client(), invitee_email)

        self.assertEquals(resp.status_code, 403)

        # no students
        resp = self.invite(self.new_student_client(Client()), invitee_email)

        self.assertEquals(resp.status_code, 403)

        # no (non-admin) instructors
        resp = self.invite(self.new_instructor_client(Client()), invitee_email)

        self.assertEquals(resp.status_code, 403)

    def test_instructor_invite_can_expire(self):
        admin_client = self.login(Client(), user=self.instructor_admin_user, password=self.instructor_admin_password)

        invitee_email = 'test-invite@test.com'

        resp = self.invite(admin_client, invitee_email)

        self.assertEquals(resp.status_code, 200, json.loads(resp.content.decode('utf8')))

        resp_content = json.loads(resp.content)

        self.assertIn('email', resp_content)
        self.assertEquals(resp_content['email'], invitee_email)

        self.assertIn('invite_code', resp_content)

        invite = Invite.objects.get(key=resp_content['invite_code'])

        invite.created = timezone.now() - timezone.timedelta(days=31)

        invite.save()

        resp = self.instructor_signup(resp_content['invite_code'], invitee_email)

        self.assertEquals(resp.status_code, 400, json.loads(resp.content.decode('utf8')))

        resp_content = json.loads(resp.content)

        self.assertIn('invite_code', resp_content)

    def test_instructor_invite(self):
        admin_client = self.login(Client(), user=self.instructor_admin_user, password=self.instructor_admin_password)

        invitee_email = 'test-invite@test.com'

        resp = self.invite(admin_client, invitee_email)

        self.assertEquals(resp.status_code, 200, json.loads(resp.content.decode('utf8')))

        resp_content = json.loads(resp.content)

        self.assertIn('email', resp_content)
        self.assertEquals(resp_content['email'], invitee_email)

        self.assertIn('invite_code', resp_content)

        resp = self.instructor_signup(resp_content['invite_code'], invitee_email)

        self.assertEquals(resp.status_code, 200, json.loads(resp.content.decode('utf8')))
