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
        user_passwd = password or self.password_strategy.example()

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
