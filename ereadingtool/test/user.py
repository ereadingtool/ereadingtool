import random
import string
import json

from typing import Dict, Union, AnyStr, List
from typing import Optional, Tuple

from django.test import TestCase
from django.test.client import Client

from collections import OrderedDict
from faker import Faker

from text_reading.models import StudentTextReading, InstructorTextReading
from user.instructor.models import Instructor
from user.models import ReaderUser
from user.student.models import Student

from ereadingtool.urls import reverse_lazy


SectionSpec = List[Dict[AnyStr, int]]
Reading = Union[StudentTextReading, InstructorTextReading]


class TestUser(TestCase):
    def __init__(self, *args, **kwargs):
        super(TestUser, self).__init__(*args, **kwargs)

        self.instructor = None
        self.user = None
        self.user_passwd = None

        self.fake = Faker(OrderedDict([
            ('en-US', 1),
        ]))

        self.fake.seed_locale('en_US', random.randint(0, 100))

    def new_user(self, password: AnyStr = None, username: AnyStr = None, is_staff: AnyStr = False) -> (ReaderUser, AnyStr):
        user = ReaderUser(is_active=True, is_staff=is_staff, username=username or ''.join(random.choices(
            string.ascii_uppercase + string.digits + string.ascii_lowercase, k=8)))

        user.email = self.fake['en-US'].email()

        user_passwd = password or ''.join(random.choices(
            string.ascii_uppercase + string.digits + string.ascii_lowercase, k=8))

        user.set_password(user_passwd)
        user.save()

        return user, user_passwd

    def new_student(self) -> (ReaderUser, AnyStr, Student):
        user, user_passwd = self.new_user()

        student = Student(user=user)
        student.save()

        return user, user_passwd, student

    def new_instructor_with_user(self, user: ReaderUser, **kwargs) -> Instructor:
        instructor = Instructor(user=user, **kwargs)
        instructor.save()

        return instructor

    def new_instructor(self) -> (ReaderUser, AnyStr, Instructor):
        user, user_passwd = self.new_user(is_staff=True)

        instructor = self.new_instructor_with_user(user)

        return user, user_passwd, instructor

    def instructor_login(self, client: Client,
              user: Optional[ReaderUser] = None,
              username: Optional[AnyStr] = None,
              password: Optional[AnyStr] = None) -> Client:
        return self.login(client, reverse_lazy('api-instructor-login'), user, username, password)

    def student_login(self, client: Client,
              user: Optional[ReaderUser] = None,
              username: Optional[AnyStr] = None,
              password: Optional[AnyStr] = None) -> Client:
        return self.login(client, reverse_lazy('api-student-login'), user, username, password)

    def login(self, client: Client, endpoint,
              user: Optional[ReaderUser] = None,
              username: Optional[AnyStr] = None,
              password: Optional[AnyStr] = None) -> Client:

        # get JWT token
        login_resp = client.post(endpoint, json.dumps({
            'username': username or user.username,
            'password': password
        }), content_type='application/json')

        login_resp_json = json.loads(login_resp.content.decode('utf8'))

        self.assertEquals(login_resp.status_code, 200, json.dumps(json.loads(login_resp.content.decode('utf8')),
                                                                  indent=4))

        self.assertIn('token_type', login_resp_json, 'no token type')
        self.assertIn('token', login_resp_json, 'no token')

        client.defaults['HTTP_AUTHORIZATION'] = f"{login_resp_json['token_type']} {login_resp_json['token']}"

        return client

    def new_instructor_client(self, client: Client,
                              user_and_pass: Optional[Tuple[ReaderUser, AnyStr]] = None) -> Client:
        if not user_and_pass:
            user, user_passwd, _ = self.new_instructor()
        else:
            user, user_passwd = user_and_pass

        client = self.instructor_login(client, user=user, password=user_passwd)

        return client

    def new_student_client(self, client: Client,
                           user_and_pass: Optional[Tuple[ReaderUser, AnyStr]] = None) -> Client:
        if not user_and_pass:
            user, user_passwd, _ = self.new_student()
        else:
            user, user_passwd = user_and_pass

        client = self.student_login(client, user=user, password=user_passwd)

        return client

