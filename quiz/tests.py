import json

from django.test import TestCase
from hypothesis.extra.django.models import models
from hypothesis.strategies import just, text

from ereadingtool.urls import reverse_lazy
from quiz.models import Quiz
from text.models import TextDifficulty, Text
from user.models import ReaderUser, Instructor


class QuizTest(TestCase):
    def __init__(self, *args, **kwargs):
        super(QuizTest, self).__init__(*args, **kwargs)

        self.instructor = None
        self.user = None
        self.user_passwd = None

        self.quiz_endpoint = reverse_lazy('quiz-api')

    def setUp(self):
        super(QuizTest, self).setUp()

        TextDifficulty.setup_default()

        self.user = models(ReaderUser, username=text(min_size=5, max_size=150)).example()
        self.user_passwd = '1234'

        self.user.set_password(self.user_passwd)
        self.user.is_active = True
        self.user.save()

        self.instructor = models(Instructor, user=just(self.user)).example()

        logged_in = self.client.login(username=self.user.username, password=self.user_passwd)

        self.assertTrue(logged_in, 'couldnt login with username="{0}" passwd="{1}"'.format(
            self.user.username, self.user_passwd))

    def test_post_quiz(self):
        test_data = {
            'title': 'quiz title',
            'texts': [
                {'title': 'title',
                 'source': 'source',
                 'difficulty': '',
                 'body': '<p style="text-align:center">text</p>\n',
                 'author': 'author',
                 'questions': [
                     {'body': 'Question 1?',
                      'order': 0,
                      'answers': [
                          {'text': 'Click to write choice 1',
                           'correct': False,
                           'order': 0,
                           'feedback': 'Answer 1 Feedback.'},
                          {'text': 'Click to write choice 2',
                           'correct': False,
                           'order': 1,
                           'feedback': 'Answer 2 Feedback.'},
                          {'text': 'Click to write choice 3',
                           'correct': False,
                           'order': 2,
                           'feedback': 'Answer 3 Feedback.'},
                          {'text': 'Click to write choice 4',
                           'correct': False,
                           'order': 3,
                           'feedback': 'Answer 4 Feedback.'}],
                      'question_type': 'main_idea'}
                 ]},
                {'title': 'title',
                 'source': 'source',
                 'difficulty': '',
                 'body': '<p style="text-align:center">cool</p>\n',
                 'author': 'author',
                 'questions': [
                     {'body': 'Question 2?',
                      'order': 0,
                      'answers': [
                          {'text': 'Click to write choice 1',
                           'correct': False,
                           'order': 0,
                           'feedback': 'Answer 1 Feedback.'},
                          {'text': 'Click to write choice 2',
                           'correct': False,
                           'order': 1,
                           'feedback': 'Answer 2 Feedback.'},
                          {'text': 'Click to write choice 3',
                           'correct': False,
                           'order': 2,
                           'feedback': 'Answer 3 Feedback.'},
                          {'text': 'Click to write choice 4',
                           'correct': False,
                           'order': 3, 'feedback': 'Answer 4 Feedback.'}
                      ],
                      'question_type': 'main_idea'}]
                 }]}

        resp = self.client.post('/api/quiz/', json.dumps({"malformed": "json"}), content_type='application/json')

        self.assertEquals(resp.status_code, 400)

        resp = self.client.post('/api/quiz/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Quiz.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        quiz = Quiz.objects.get(pk=resp_content['id'])

        self.assertEquals(Text.objects.count(), 2)

        resp = self.client.get('/api/quiz/{0}/'.format(quiz.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['title'], 'quiz title')
