from typing import AnyStr, Optional, Tuple

from django.test import TestCase
from django.test.client import Client
from hypothesis.extra.django.models import models
from hypothesis.strategies import just, text

from user.models import ReaderUser

from user.instructor.models import Instructor
from user.student.models import Student


class TestUser(TestCase):
    def __init__(self, *args, **kwargs):
        super(TestUser, self).__init__(*args, **kwargs)

        self.instructor = None
        self.user = None
        self.user_passwd = None

    def new_user(self) -> (ReaderUser, AnyStr):
        user = models(ReaderUser, username=text(min_size=5, max_size=150)).example()
        user_passwd = text(min_size=8, max_size=12).example()

        user.set_password(user_passwd)
        user.is_active = True
        user.save()

        return user, user_passwd

    def new_student(self) -> (ReaderUser, AnyStr, Student):
        user, user_passwd = self.new_user()

        student = models(Student, user=just(user)).example()

        return user, user_passwd, student

    def new_instructor_client(self, client: Client) -> Client:
        user, user_passwd = self.new_user()

        instructor = models(Instructor, user=just(user)).example()
        instructor.save()

        logged_in = client.login(username=user.username, password=user_passwd)

        self.assertTrue(logged_in, 'couldnt login with username="{0}" passwd="{1}"'.format(user.username, user_passwd))

        return client

    def new_student_client(self, client: Client, user_and_pass: Optional[Tuple[ReaderUser, AnyStr]]=None) -> Client:
        user, user_passwd = user_and_pass or self.new_user()

        student = models(Student, user=just(user)).example()
        student.save()

        logged_in = client.login(username=user.username, password=user_passwd)

        self.assertTrue(logged_in, 'couldnt login with username="{0}" passwd="{1}"'.format(user.username, user_passwd))

        return client
