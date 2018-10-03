import json
from typing import Dict, Union, AnyStr, List

import re

from django.test import TestCase

from django.test.client import Client

from django.utils import timezone as dt

from django.http.response import HttpResponse, HttpResponseRedirect

from ereadingtool.test.user import TestUser as TestUserBase
from django.urls import reverse
from django.core import mail

from text.models import Text
from text.tests import TestText

from text_reading.models import StudentTextReading, InstructorTextReading

SectionSpec = List[Dict[AnyStr, int]]
Reading = Union[StudentTextReading, InstructorTextReading]


class TestUser(TestUserBase, TestCase):
    def setUp(self):
        super(TestUser, self).setUp()

        self.anonymous_client = Client()

        self.student_user, self.student_passwd, self.student_profile = self.new_student()

        self.student_client = self.new_student_client(Client(), user_and_pass=(self.student_user, self.student_passwd))

        self.student_api_endpoint = reverse('api-student', args=[self.student_profile.pk])
        self.student_login_api_endpoint = reverse('api-student-login')

        self.password_reset_api_endpoint = reverse('api-password-reset')
        self.password_reset_confirm_api_endpoint = reverse('api-password-reset-confirm')

    def test_read(self, text: Text, text_reading: Reading, sections: SectionSpec, end_dt: dt.datetime=None) -> Reading:
        section_num = 0

        text_sections = text.sections.all()

        self.assertEquals(text_reading.current_state, text_reading.state_machine.intro)

        text_reading.next()

        for section in text_sections:
            questions = section.questions.all()

            self.assertGreaterEqual(len(questions), sections[section_num]['answered_correctly'])

            self.assertEquals(text_reading.current_state, text_reading.state_machine.in_progress)
            self.assertEquals(text_reading.current_section, section)

            answered_correctly = 0

            for question in questions:
                answers = question.answers.all()

                # answer questions correctly or incorrectly based on parameters
                # answer i=3 is always correct unless otherwise specified
                correct_answer = answers[3]
                an_incorrect_answer = answers[1]

                self.assertTrue(correct_answer.correct)
                self.assertFalse(an_incorrect_answer.correct)

                if answered_correctly < sections[section_num]['answered_correctly']:
                    text_reading.answer(correct_answer)
                    answered_correctly += 1
                else:
                    text_reading.answer(an_incorrect_answer)

            section_num += 1
            text_reading.next()

        if end_dt:
            # custom text reading end dt
            text_reading.end_dt = end_dt
            text_reading.save()

        return text_reading

    def test_student_performance_report(self):
        test_text = TestText()
        test_text.setUp()

        today_dt = dt.now()

        # 3 sections, with 7, 2, and 3 questions, respectively (total questions: 12)
        text_params = test_text.generate_text_params(
            sections=[{'num_of_questions': 7}, {'num_of_questions': 2}, {'num_of_questions': 3}])

        text = test_text.test_post_text(test_data=text_params)
        text_reading = StudentTextReading.start(student=self.student_profile, text=text)

        # complete each section with 2, 2, and 0 correctly answered questions, respectively
        # (total answered correctly: 4)
        student_text_reading = self.test_read(text=text, text_reading=text_reading, sections=[
            {'answered_correctly': 2},
            {'answered_correctly': 2},
            {'answered_correctly': 0},
        ], end_dt=today_dt)

        self.assertEquals(student_text_reading.current_state, student_text_reading.state_machine.complete)

        performance_report = self.student_profile.performance.to_dict()

        # 4 / 12 = 0.33
        self.assertEquals(performance_report['all']['cumulative'], {'percent_correct': 0.3333333333333333,
                                                                    'texts_complete': 1})

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

        # test we can still login via e-mail address
        resp = self.student_client.post(self.student_login_api_endpoint,
                                        data=json.dumps(
                                            {'username': self.student_user.email, 'password': self.student_passwd}),
                                        content_type='application/json')

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
