import json

from django.test import TestCase
from hypothesis.extra.django.models import models
from hypothesis.strategies import just, text

from typing import Union, Any
from django.test.client import Client

from ereadingtool.urls import reverse_lazy
from quiz.models import Quiz
from tag.models import Tag
from text.models import TextDifficulty, Text
from user.models import ReaderUser, Instructor
from question.models import Answer


class QuizTest(TestCase):
    def __init__(self, *args, **kwargs):
        super(QuizTest, self).__init__(*args, **kwargs)

        self.instructor = None
        self.user = None
        self.user_passwd = None

        self.quiz_endpoint = reverse_lazy('quiz-api')

    def new_instructor(self, client: Client) -> Client:
        user = models(ReaderUser, username=text(min_size=5, max_size=150)).example()
        user_passwd = text(min_size=8, max_size=12).example()

        user.set_password(user_passwd)
        user.is_active = True
        user.save()

        instructor = models(Instructor, user=just(user)).example()
        instructor.save()

        logged_in = client.login(username=user.username, password=user_passwd)

        self.assertTrue(logged_in, 'couldnt login with username="{0}" passwd="{1}"'.format(user.username, user_passwd))

        return client

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

    def create_quiz(self, diff_data: dict=None) -> Quiz:
        quiz_data = self.get_test_data()

        if diff_data:
            quiz_data.update(diff_data)

        resp = self.client.post('/api/quiz/', json.dumps(quiz_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        quiz = Quiz.objects.get(pk=resp_content['id'])

        return quiz

    def test_quiz_tags(self):
        test_data = self.get_test_data()

        quiz_one = self.create_quiz()
        quiz_two = self.create_quiz(diff_data={'tags': ['Society and Societal Trends']})

        resp = self.client.put('/api/quiz/{0}/tag/'.format(quiz_one.pk), json.dumps('Society and Societal Trends'),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz_one.tags.count(), len(test_data['tags'])+1)

        self.assertIn('Society and Societal Trends', [tag.name for tag in quiz_one.tags.all()])

        resp = self.client.put('/api/quiz/{0}/tag/'.format(quiz_one.pk),
                               json.dumps(['Sports', 'Science/Technology', 'Other']),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz_one.tags.count(), 4)

        resp = self.client.delete('/api/quiz/{0}/tag/'.format(quiz_one.pk),
                                  json.dumps('Other'),
                                  content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz_one.tags.count(), 3)
        self.assertEquals(quiz_two.tags.count(), 1)

        resp = self.client.delete('/api/quiz/{0}/tag/'.format(quiz_two.pk),
                                  json.dumps('Society and Societal Trends'),
                                  content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz_one.tags.count(), 3)
        self.assertEquals(quiz_two.tags.count(), 0)

        quiz_three = self.create_quiz(diff_data={'tags': ['Science/Technology']})

        science_tech_tag = Tag.objects.get(name='Science/Technology')

        self.assertEquals(science_tech_tag.quizzes.count(), 2)

    def test_put_quiz(self):
        test_data = self.get_test_data()

        resp = self.client.post('/api/quiz/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Quiz.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        quiz = Quiz.objects.get(pk=resp_content['id'])

        test_data['title'] = 'a new quiz title'
        test_data['introduction'] = 'a new introduction'
        test_data['texts'][1]['author'] = 'J. K. Idding'

        resp = self.client.put('/api/quiz/{pk}/'.format(pk=quiz.pk), json.dumps(test_data),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.client.get('/api/quiz/{0}/'.format(quiz.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['title'], 'a new quiz title')

        self.assertEquals(resp_content['texts'][1]['author'], 'J. K. Idding')

        self.assertEquals(resp_content['introduction'], 'a new introduction')

        test_data['texts'][1]['questions'][0]['body'] = 'A new question?'
        test_data['texts'][1]['questions'][0]['answers'][1]['text'] = 'A new answer.'

        resp = self.client.put('/api/quiz/{pk}/'.format(pk=quiz.pk), json.dumps(test_data),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.client.get('/api/quiz/{0}/'.format(quiz.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['texts'][1]['questions'][0]['body'], 'A new question?')
        self.assertEquals(resp_content['texts'][1]['questions'][0]['answers'][1]['text'], 'A new answer.')

    def test_quiz_lock(self):
        other_instructor_client = self.new_instructor(Client())

        resp = self.client.post('/api/quiz/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        quiz = Quiz.objects.get(pk=resp_content['id'])

        resp = self.client.post('/api/quiz/{0}/lock/'.format(quiz.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post('/api/quiz/{0}/lock/'.format(quiz.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.delete('/api/quiz/{0}/lock/'.format(quiz.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.client.delete('/api/quiz/{0}/lock/'.format(quiz.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post('/api/quiz/{0}/lock/'.format(quiz.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.client.post('/api/quiz/{0}/lock/'.format(quiz.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_quiz_max_char_limits(self):
        test_data = self.get_test_data()

        answer_feedback_limit = Answer._meta.get_field('feedback').max_length

        test_data['texts'][0]['questions'][0]['answers'][0]['feedback'] = 'a' * (answer_feedback_limit +1)

        resp = self.client.post('/api/quiz/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('text_0_question_0_answer_0_feedback', resp_content['errors'])

        self.assertEquals(resp_content['errors']['text_0_question_0_answer_0_feedback'],
                          'Ensure this value has at most '
                          '{0} characters (it has {1}).'.format(answer_feedback_limit, (answer_feedback_limit+1)))

    def test_post_quiz(self):
        resp = self.client.post('/api/quiz/', json.dumps({"malformed": "json"}), content_type='application/json')

        self.assertEquals(resp.status_code, 400)

        resp = self.client.post('/api/quiz/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Quiz.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)
        self.assertIn('redirect', resp_content)

        quiz = Quiz.objects.get(pk=resp_content['id'])

        self.assertEquals(Text.objects.count(), 2)

        resp = self.client.get('/api/quiz/{0}/'.format(quiz.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['title'], 'quiz title')
        self.assertEquals(resp_content['introduction'], 'an introductory text')
        self.assertEquals(resp_content['tags'], ['Sports', 'Science/Technology', 'Other'])

    def test_delete_quiz(self):
        resp = self.client.post('/api/quiz/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Quiz.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.client.delete('/api/quiz/{0}/'.format(resp_content['id']), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertTrue('deleted' in resp_content)

    def get_test_data(self):
        return {
            'title': 'quiz title',
            'introduction': 'an introductory text',
            'tags': ['Sports', 'Science/Technology', 'Other'],
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