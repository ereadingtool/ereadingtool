import json

from django.test import TestCase
from hypothesis.extra.django.models import models
from hypothesis.strategies import just, text

from typing import Dict
from django.test.client import Client

from ereadingtool.urls import reverse_lazy
from tag.models import Tag
from text.models import TextDifficulty, Text, TextSection
from user.models import ReaderUser, Instructor
from question.models import Answer


class TextTest(TestCase):
    def __init__(self, *args, **kwargs):
        super(TextTest, self).__init__(*args, **kwargs)

        self.instructor = None
        self.user = None
        self.user_passwd = None

        self.text_endpoint = reverse_lazy('text-api')

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
        super(TextTest, self).setUp()

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

    def create_text(self, diff_data: dict=None) -> Text:
        text_data = self.get_test_data()

        if diff_data:
            text_data.update(diff_data)

        resp = self.client.post('/api/text/', json.dumps(text_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        text = Text.objects.get(pk=resp_content['id'])

        return text

    def test_text_tags(self):
        test_data = self.get_test_data()

        text_one = self.create_text()
        text_two = self.create_text(diff_data={'tags': ['Society and Societal Trends']})

        resp = self.client.put('/api/text/{0}/tag/'.format(text_one.pk), json.dumps('Society and Societal Trends'),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), len(test_data['tags'])+1)

        self.assertIn('Society and Societal Trends', [tag.name for tag in text_one.tags.all()])

        resp = self.client.put('/api/text/{0}/tag/'.format(text_one.pk),
                               json.dumps(['Sports', 'Science/Technology', 'Other']),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 4)

        resp = self.client.delete('/api/text/{0}/tag/'.format(text_one.pk),
                                  json.dumps('Other'),
                                  content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 3)
        self.assertEquals(text_two.tags.count(), 1)

        resp = self.client.delete('/api/text/{0}/tag/'.format(text_two.pk),
                                  json.dumps('Society and Societal Trends'),
                                  content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 3)
        self.assertEquals(text_two.tags.count(), 0)

        text_three = self.create_text(diff_data={'tags': ['Science/Technology']})

        science_tech_tag = Tag.objects.get(name='Science/Technology')

        self.assertEquals(science_tech_tag.texts.count(), 2)

    def test_put_new_section(self):
        test_data = self.get_test_data()

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        text_id = resp_content['id']

        test_data['text_sections'].append(self.gen_text_section_params(2))

        resp = self.client.put(f'/api/text/{text_id}/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        text = Text.objects.get(pk=text_id)

        self.assertEquals(3, text.sections.count())

    def test_put_text(self):
        test_data = self.get_test_data()

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        text = Text.objects.get(pk=resp_content['id'])

        test_data['title'] = 'a new text title'
        test_data['introduction'] = 'a new introduction'
        test_data['author'] = 'J. K. Idding'

        resp = self.client.put('/api/text/{pk}/'.format(pk=text.pk), json.dumps(test_data),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.client.get('/api/text/{0}/'.format(text.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertIn('difficulty', resp_content)

        self.assertEquals(resp_content['title'], 'a new text title')
        self.assertEquals(resp_content['introduction'], 'a new introduction')
        self.assertEquals(resp_content['author'], 'J. K. Idding')

        test_data['text_sections'][1]['questions'][0]['body'] = 'A new question?'
        test_data['text_sections'][1]['questions'][0]['answers'][1]['text'] = 'A new answer.'

        resp = self.client.put('/api/text/{pk}/'.format(pk=text.pk), json.dumps(test_data),
                               content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.client.get('/api/text/{0}/'.format(text.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['text_sections'][1]['questions'][0]['body'], 'A new question?')
        self.assertEquals(resp_content['text_sections'][1]['questions'][0]['answers'][1]['text'], 'A new answer.')

    def test_text_lock(self):
        other_instructor_client = self.new_instructor(Client())

        resp = self.client.post('/api/text/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        resp = self.client.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.delete('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.client.delete('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.client.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_text_correct_answers(self):
        test_data = self.get_test_data()

        for answer in test_data['text_sections'][0]['questions'][0]['answers']:
            answer['correct'] = False

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('textsection_0_question_0_answers', resp_content['errors'])
        self.assertEquals('exactly one correct answer is required',
                          resp_content['errors']['textsection_0_question_0_answers'])

        # set one correct answer
        test_data['text_sections'][0]['questions'][0]['answers'][0]['correct'] = True

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_text_max_char_limits(self):
        test_data = self.get_test_data()
        test_text_section_body_size = 4096

        answer_feedback_limit = Answer._meta.get_field('feedback').max_length

        # answer feedback limited
        test_data['text_sections'][0]['questions'][0]['answers'][0]['feedback'] = 'a' * (answer_feedback_limit + 1)
        # no limit for text section bodies
        test_data['text_sections'][0]['body'] = 'a' * test_text_section_body_size

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('textsection_0_question_0_answer_0_feedback', resp_content['errors'])

        self.assertEquals(resp_content['errors']['textsection_0_question_0_answer_0_feedback'],
                          'Ensure this value has at most '
                          '{0} characters (it has {1}).'.format(answer_feedback_limit, (answer_feedback_limit+1)))

        self.assertNotIn('textsection_0_body', resp_content['errors'])

        test_data['text_sections'][0]['questions'][0]['answers'][0]['feedback'] = 'a'

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertNotIn('errors', resp_content)
        self.assertIn('id', resp_content)

        # ensure db doesn't truncate
        text_section = TextSection.objects.get(pk=resp_content['id'])

        self.assertEquals(len(text_section.body), test_text_section_body_size)

    def test_post_text(self):
        test_data = self.get_test_data()

        resp = self.client.post('/api/text/', json.dumps({"malformed": "json"}), content_type='application/json')

        self.assertEquals(resp.status_code, 400)

        resp = self.client.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)
        self.assertIn('redirect', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        self.assertEquals(TextSection.objects.count(), 2)

        resp = self.client.get('/api/text/{0}/'.format(text.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['title'], test_data['title'])
        self.assertEquals(resp_content['introduction'], test_data['introduction'])
        self.assertEquals(resp_content['tags'], test_data['tags'])

    def test_delete_text(self):
        resp = self.client.post('/api/text/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.client.delete('/api/text/{0}/'.format(resp_content['id']), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertTrue('deleted' in resp_content)

    def gen_text_section_params(self, order: int) -> Dict:
        return {
            'order': order,
            'body': f'<p style="text-align:center">section {order}</p>\n',
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
                   'correct': True,
                   'order': 3, 'feedback': 'Answer 4 Feedback.'}
                  ], 'question_type': 'main_idea'}]
         }

    def get_test_data(self) -> Dict:
        return {
            'title': 'text title',
            'introduction': 'an introduction to the text',
            'tags': ['Sports', 'Science/Technology', 'Other'],
            'author': 'author',
            'source': 'source',
            'text_sections': [self.gen_text_section_params(0), self.gen_text_section_params(1)]
        }
