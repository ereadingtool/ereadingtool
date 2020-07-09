import random
import string
import json

from typing import Dict, Union, AnyStr, List
from typing import Optional, Tuple

from django.test import TestCase
from django.test.client import Client

from hypothesis.extra.django import from_model
from hypothesis.strategies import just, text

from text_reading.models import StudentTextReading, InstructorTextReading
from user.instructor.models import Instructor
from user.models import ReaderUser
from user.student.models import Student

from ereadingtool.test.data import TestData

from ereadingtool.urls import reverse_lazy


SectionSpec = List[Dict[AnyStr, int]]
Reading = Union[StudentTextReading, InstructorTextReading]


class TestUser(TestCase):
    def __init__(self, *args, **kwargs):
        super(TestUser, self).__init__(*args, **kwargs)

        self.instructor = None
        self.user = None
        self.user_passwd = None

        self.username_strategy = text(min_size=5, max_size=150)
        self.password_strategy = text(min_size=8, max_size=12)

    def new_user(self, password: AnyStr = None, username: AnyStr = None) -> (ReaderUser, AnyStr):
        reader_user_params = {
            'is_active': just(True),
            'username': just(username) if username else self.username_strategy
        }

        user = from_model(ReaderUser, **reader_user_params).example()
        user_passwd = password or ''.join(random.choices(
            string.ascii_uppercase + string.digits + string.ascii_lowercase, k=8))

        user.set_password(user_passwd)
        user.save()

        return user, user_passwd

    def new_student(self) -> (ReaderUser, AnyStr, Student):
        user, user_passwd = self.new_user()

        student = from_model(Student, user=just(user)).example()

        return user, user_passwd, student

    def new_instructor_with_user(self, user: ReaderUser, **kwargs) -> Instructor:
        instructor = from_model(Instructor, user=just(user), **kwargs).example()

        return instructor

    def new_instructor(self) -> (ReaderUser, AnyStr, Instructor):
        user, user_passwd = self.new_user()

        instructor = self.new_instructor_with_user(user)

        return user, user_passwd, instructor

    def login(self, client: Client, user_and_pass: Optional[Tuple[ReaderUser, AnyStr]] = None) -> Client:
        user, user_passwd = user_and_pass or self.new_user()

        logged_in = client.login(username=user.username, password=user_passwd)

        self.assertTrue(logged_in, 'couldnt login with username="{0}" passwd="{1}"'.format(user.username, user_passwd))

        return client

    def new_instructor_client(self, client: Client,
                              user_and_pass: Optional[Tuple[ReaderUser, AnyStr]] = None) -> Client:
        if not user_and_pass:
            user, user_passwd, _ = self.new_instructor()

            user_and_pass = (user, user_passwd)

        client = self.login(client, user_and_pass)

        return client

    def new_student_client(self, client: Client,
                           user_and_pass: Optional[Tuple[ReaderUser, AnyStr]] = None) -> Client:
        if not user_and_pass:
            user, user_passwd, _ = self.new_student()

            user_and_pass = (user, user_passwd)

        client = self.login(client, user_and_pass)

        return client


class TestUserLogin(TestData, TestUser):
    def test_user_can_login_with_jwt(self):
        user_passwd = 'test'
        reader_user = ReaderUser(is_active=True, username='test@test.com')

        reader_user.set_password(user_passwd)
        reader_user.save()

        text_data = self.get_test_data()

        unauthed_client = Client()

        # get JWT token
        login_resp = unauthed_client.post(reverse_lazy('jwt-token-auth'),
                                          json.dumps({
                                           'username': reader_user.username,
                                           'password': 'test'
                                          }), content_type='application/json')

        login_resp_json = json.loads(login_resp.content.decode('utf8'))

        self.assertEquals(login_resp.status_code, 200, json.dumps(json.loads(login_resp.content.decode('utf8')),
                                                                  indent=4))

        resp = unauthed_client.post(reverse_lazy('text-api'),
                                    json.dumps(text_data),
                                    content_type='application/json',
                                    HTTP_AUTHORIZATION=f"{login_resp_json['token_type']} {login_resp_json['token']}"
                                    )

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8') or '{}'), indent=4))

        _ = json.loads(resp.content.decode('utf8'))

        return text
