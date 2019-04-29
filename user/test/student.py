import json
import re
from typing import Dict, Union, AnyStr, List

from django.core import mail
from django.http.response import HttpResponse, HttpResponseRedirect
from django.test import TestCase
from django.test.client import Client
from django.urls import reverse
from django.utils import timezone as dt

from ereadingtool.test.user import TestUser
from ereadingtool.test.data import TestData

from text.models import Text, TextDifficulty
from text.tests import TestText
from text_reading.models import StudentTextReading, InstructorTextReading

from user.student.models import Student


SectionSpec = List[Dict[AnyStr, int]]
Reading = Union[StudentTextReading, InstructorTextReading]


class TestStudentUser(TestData, TestUser, TestCase):
    def setUp(self):
        super(TestStudentUser, self).setUp()

        self.anonymous_client = Client()

        self.student_user, self.student_passwd, self.student_profile = self.new_student()

        self.student_client = self.new_student_client(Client(), user_and_pass=(self.student_user, self.student_passwd))

        self.student_api_endpoint = reverse('api-student', args=[self.student_profile.pk])
        self.student_login_api_endpoint = reverse('api-student-login')

        self.password_reset_api_endpoint = reverse('api-password-reset')
        self.password_reset_confirm_api_endpoint = reverse('api-password-reset-confirm')

    def read_test(self, text: Text, text_reading: Reading, sections: SectionSpec,
                  end_dt: dt.datetime = None) -> Reading:
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

        if today_dt.month == 1:
            last_month_dt = today_dt.replace(month=12, year=today_dt.year - 1)
        else:
            last_month_dt = today_dt.replace(month=today_dt.month - 1)

        # 3 sections, with 7, 2, and 3 questions, respectively (total questions: 12)
        text_params = test_text.generate_text_params(
            sections=[{'num_of_questions': 7}, {'num_of_questions': 2}, {'num_of_questions': 3}])

        text = test_text.test_post_text(test_data=text_params)
        text_reading = StudentTextReading.start(student=self.student_profile, text=text)

        # complete each section with 0, 1, and 1 correctly answered questions, respectively
        # (total answered correctly: 2) first of last month
        student_text_reading = self.read_test(text=text, text_reading=text_reading, sections=[
            {'answered_correctly': 0},
            {'answered_correctly': 1},
            {'answered_correctly': 1},
        ], end_dt=last_month_dt.replace(day=1))

        self.assertEquals(student_text_reading.current_state, student_text_reading.state_machine.complete)

        text_reading_two = StudentTextReading.start(student=self.student_profile, text=text)

        # complete each section with 2, 2, and 0 correctly answered questions, respectively
        # (total answered correctly: 4)
        student_text_reading_two = self.read_test(text=text, text_reading=text_reading_two, sections=[
            {'answered_correctly': 2},
            {'answered_correctly': 2},
            {'answered_correctly': 0},
        ], end_dt=today_dt)

        self.assertEquals(student_text_reading_two.current_state,
                          student_text_reading_two.state_machine.complete)

        performance_report = self.student_profile.performance.to_dict()

        # for all categories except 'all' and text.difficulty.slug should be blank
        report_minus_other_categories = performance_report.copy()

        report_minus_other_categories.pop('all')
        report_minus_other_categories.pop(text.difficulty.slug)

        for difficulty in report_minus_other_categories:
            self.assertEquals(report_minus_other_categories[difficulty]['categories'], {
                'cumulative': {
                    'metrics': {'percent_correct': None, 'texts_complete': 0, 'total_texts': 0},
                    'title': 'Cumulative'},
                'current_month': {
                    'metrics': {'percent_correct': None, 'texts_complete': 0, 'total_texts': 0},
                    'title': 'Current Month'},
                'past_month': {
                    'metrics': {'percent_correct': None, 'texts_complete': 0, 'total_texts': 0},
                    'title': 'Past Month'
                }
            }, f'{difficulty} should be empty for the report.')

        # current month 4 / 12 ~= 33.33%
        self.assertEquals(performance_report['all']['categories']['current_month'], {
            'metrics': {'percent_correct': 33.33, 'texts_complete': 1, 'total_texts': 1},
            'title': 'Current Month'
        })

        self.assertEquals(performance_report[text.difficulty.slug]['categories'], {
            # cumulative (2 + 4 correct total out of 24 attempts) ~= 25.0%
            'cumulative': {
                'metrics': {'percent_correct': 25.0, 'texts_complete': 1, 'total_texts': 1},
                'title': 'Cumulative'
            },
            # current month 4 / 12 ~= 33.33%
            'current_month': {
                'metrics': {'percent_correct': 33.33, 'texts_complete': 1, 'total_texts': 1},
                'title': 'Current Month'
            },
            # 2 / 12 ~= 16.67%
            'past_month': {
                'metrics': {'percent_correct': 16.67, 'texts_complete': 1, 'total_texts': 1},
                'title': 'Past Month'
            }
        })

    def test_student_signup(self, student_signup_params: Dict = None) -> Client:
        if not student_signup_params:
            student_signup_params = {
                'email': 'testing@test.com',
                'password': 'p4ssw0rd12!',
                'confirm_password': 'p4ssw0rd12!',
                'difficulty': TextDifficulty.objects.get(pk=1).slug
            }

        signup_uri = reverse('api-student-signup')

        anonymous_client = Client()

        signup_resp = anonymous_client.post(signup_uri, data=json.dumps(student_signup_params),
                                            content_type='application/json')

        self.assertEquals(signup_resp.status_code, 200, signup_resp.content)

        return anonymous_client

    def test_welcome_flag(self):
        student_profile_url = reverse('load-elm-student')
        search_url = reverse('text-search-load-elm')

        student_signup_params = {
            'email': 'testing@test.com',
            'password': 'p4ssw0rd12!',
            'confirm_password': 'p4ssw0rd12!',
            'difficulty': TextDifficulty.objects.get(pk=1).slug
        }

        student_client = self.test_student_signup(student_signup_params)

        student_login_resp = student_client.post(self.student_login_api_endpoint,
                                                 data=json.dumps({'username': student_signup_params['email'],
                                                                  'password': student_signup_params['password']}),
                                                 content_type='application/json')

        # welcome flag should be present on the first loading of the profile page, but not on subsequent loads
        def match_welcome_flag(resp: HttpResponse) -> bool:
            welcome_re = re.compile(r'.+welcome\s*:(?P<welcome>\w+).+', re.IGNORECASE | re.DOTALL)

            matches = welcome_re.match(str(resp.content))

            self.assertTrue(matches, 'no welcome flag')

            welcome_flag = json.loads(matches.group('welcome'))

            return welcome_flag

        # present
        first_profile_resp = student_client.get(student_profile_url)

        welcome = match_welcome_flag(first_profile_resp)

        self.assertTrue(welcome)

        # not present
        second_profile_resp = student_client.get(student_profile_url)

        welcome = match_welcome_flag(second_profile_resp)

        self.assertFalse(welcome)

        # same with search page
        first_search_resp = student_client.get(search_url)

        # present
        welcome = match_welcome_flag(first_search_resp)

        self.assertTrue(welcome)

        second_search_resp = student_client.get(search_url)

        # not present
        welcome = match_welcome_flag(second_search_resp)

        self.assertFalse(welcome)

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

    def test_student_research_consent(self):
        student = Student.objects.get(pk=self.student_profile.pk)

        self.assertIsNone(student.research_consent)

        resp = self.student_client.put(self.student_api_endpoint,
                                       data=json.dumps({'consent_to_research': True}), content_type='application/json')

        self.assertTrue(resp)

        resp_content = json.loads(resp.content)

        self.assertEquals(resp.status_code, 200, resp_content)

        student = Student.objects.get(pk=self.student_profile.pk)

        self.assertIsNotNone(student.research_consent)
        self.assertIsNotNone(student.research_consent.latest_consent_range)

        self.assertIsNotNone(student.research_consent.latest_consent_range.start_dt)
        self.assertIsNone(student.research_consent.latest_consent_range.end_dt)
