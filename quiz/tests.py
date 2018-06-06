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

    def test_quiz_tags(self):
        test_data = self.get_test_data()

        resp = self.client.post('/api/quiz/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Quiz.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        quiz = Quiz.objects.get(pk=resp_content['id'])

        resp = self.client.put('/api/quiz/{0}/tag/'.format(quiz.pk), json.dumps('Society and Societal Trends'),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz.tags.count(), 1)

        self.assertEquals([tag.name for tag in quiz.tags.all()], ['Society and Societal Trends'])

        resp = self.client.put('/api/quiz/{0}/tag/'.format(quiz.pk),
                               json.dumps(['Sports', 'Science/Technology', 'Other']),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz.tags.count(), 4)

        resp = self.client.delete('/api/quiz/{0}/tag/'.format(quiz.pk),
                                  json.dumps('Other'),
                                  content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(quiz.tags.count(), 3)

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