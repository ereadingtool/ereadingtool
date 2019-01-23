from django.test import TestCase
from django.test.client import Client

from ereadingtool.test.user import TestUser as TestUserBase
from text.models import TextDifficulty


class TestInstructorUser(TestUserBase, TestCase):
    def setUp(self):
        super(TestInstructorUser, self).setUp()

        TextDifficulty.setup_default()

        self.anonymous_client = Client()

        self.instructor_user, self.instructor_passwd, self.instructor_profile = self.new_instructor()

        self.student_client = self.new_instructor_client(Client(), user_and_pass=(
            self.instructor_user, self.instructor_passwd))

    def test_instructor_invite(self):
        pass

    def test_admin_instructor(self):
        pass
