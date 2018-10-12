import json
import channels.layers

from typing import Dict, AnyStr, Optional, List

from asgiref.sync import async_to_sync
from django.test import TestCase
from django.test.client import Client
from hypothesis.strategies import just, one_of

from ereadingtool.test.user import TestUser
from ereadingtool.urls import reverse_lazy

from question.models import Answer

from tag.models import Tag

from text.models import TextDifficulty, Text, TextSection

from text_reading.base import TextReadingNotAllQuestionsAnswered
from text_reading.models import StudentTextReading

from user.student.models import Student

from text.glosbe.api import GlosbeAPI, GlosbeDefinitions, GlosbeDefinition
from text.consumers.instructor import ParseTextSectionForDefinitions


class TestText(TestUser, TestCase):
    def __init__(self, *args, **kwargs):
        super(TestText, self).__init__(*args, **kwargs)

        self.text_endpoint = reverse_lazy('text-api')

    def test_definition_objs(self):
        glosbe_api = GlosbeAPI()

        defs = glosbe_api.translate('заявление')

        self.assertIsInstance(defs, GlosbeDefinitions)

        definitions = list(defs.definitions.values())

        self.assertIsInstance(definitions[0], GlosbeDefinition)

    def test_word_definition_background_job(self):
        test_data = self.get_test_data()

        test_data['text_sections'][0]['body'] = 'заявление'
        test_data['text_sections'][1]['body'] = 'заявление'

        self.test_post_text(test_data=test_data)

        # receive one message from the channel layer
        channel_layer = channels.layers.get_channel_layer()

        ret = async_to_sync(channel_layer.receive)('text')

        self.assertTrue(ret)

        # process the message and test the output
        text_parse_consumer = ParseTextSectionForDefinitions(scope=ret)

        text_section_definitions = text_parse_consumer.text_section_parse_word_definitions(
            text_section_pk=ret['text_section_pk'])

        self.assertTrue(text_section_definitions)

        self.assertEquals(text_section_definitions.words.count(), 1)

        text_section_word = text_section_definitions.words.all()[0]

        self.assertTrue(text_section_word.meanings.count())

        text_section_word_meaning = text_section_word.meanings.all()[0]

        self.assertTrue(text_section_word_meaning.text)

    def test_text_reading(self, student: Student=None) -> StudentTextReading:
        # add an additional question for testing
        test_data = self.get_test_data()

        test_data['text_sections'][0]['questions'].append(self.gen_text_section_question_params(order=1))
        num_of_questions = len(test_data['text_sections'][0]['questions'])

        if not student:
            _, _, student = self.new_student()

        text_obj = self.create_text(diff_data=test_data)

        text_sections = text_obj.sections.all()

        self.assertEquals(text_sections[0].questions.count(), num_of_questions)

        text_reading = StudentTextReading.start(student=student, text=text_obj)

        self.assertEquals(text_reading.current_state, text_reading.state_machine.intro)

        text_reading.next()

        self.assertEquals(text_reading.current_state, text_reading.state_machine.in_progress)
        self.assertEquals(text_reading.current_section, text_sections[0])

        # answer questions
        questions = text_sections[0].questions.all()
        answer_one = questions[0].answers.all()[2]

        text_reading.answer(answer_one)

        # test cannot move to the next state if not all questions have been answered
        self.assertRaises(TextReadingNotAllQuestionsAnswered, lambda: text_reading.next())

        self.assertEquals(text_reading.current_state, text_reading.state_machine.in_progress)
        self.assertEquals(text_reading.current_section, text_sections[0])

        # answer the final question for this section
        answer_two = questions[1].answers.all()[3]

        text_reading.answer(answer_two)

        # now we should be able to move on
        text_reading.next()

        self.assertEquals(text_reading.current_state, text_reading.state_machine.in_progress)
        self.assertEquals(text_reading.current_section, text_sections[1])

        # and complete
        text_reading.next()

        self.assertEquals(text_reading.current_state, text_reading.state_machine.complete)
        self.assertEquals(text_reading.current_section, None)

        self.assertTrue(text_reading.end_dt)

        return text_reading

    def setUp(self):
        super(TestText, self).setUp()

        Tag.setup_default()
        TextDifficulty.setup_default()

        self.instructor = self.new_instructor_client(Client())
        self.student = self.new_student_client(Client())

    def create_text(self, test_data: Dict=None, diff_data: Dict=None) -> Text:
        text_data = test_data or self.get_test_data()

        if diff_data:
            text_data.update(diff_data)

        resp = self.instructor.post('/api/text/', json.dumps(text_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        text = Text.objects.get(pk=resp_content['id'])

        return text

    def test_text_tags(self):
        test_data = self.get_test_data()

        text_one = self.create_text()
        text_two = self.create_text(diff_data={'tags': ['Society and Societal Trends']})

        resp = self.instructor.put('/api/text/{0}/tag/'.format(text_one.pk), json.dumps('Society and Societal Trends'),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), len(test_data['tags'])+1)

        self.assertIn('Society and Societal Trends', [tag.name for tag in text_one.tags.all()])

        resp = self.instructor.put('/api/text/{0}/tag/'.format(text_one.pk),
                                   json.dumps(['Sports', 'Science/Technology', 'Other']),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 4)

        resp = self.instructor.delete('/api/text/{0}/tag/'.format(text_one.pk),
                                      json.dumps('Other'),
                                      content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 3)
        self.assertEquals(text_two.tags.count(), 1)

        resp = self.instructor.delete('/api/text/{0}/tag/'.format(text_two.pk),
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

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        text_id = resp_content['id']

        test_data['text_sections'].append(self.gen_text_section_params(2))

        resp = self.instructor.put(f'/api/text/{text_id}/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        text = Text.objects.get(pk=text_id)

        self.assertEquals(3, text.sections.count())

    def test_get_text_by_tag_or(self):
        student = Student.objects.get()

        test_tags = list()

        text_one = self.create_text()
        text_two = self.create_text(diff_data={'tags': ['Economics/Business', 'Medicine/Health Care']})

        test_tags.append(text_one.tags.all()[0])
        test_tags.append(text_two.tags.all()[1])

        # tag search should be ORed
        tag_search = '&'.join([f'tag={tag}' for tag in test_tags])

        resp = self.student.get(f'/api/text/?{tag_search}')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertListEqual(resp_content, [text_one.to_summary_dict(student=student),
                                            text_two.to_summary_dict(student=student)])

    def test_put_text(self):
        test_data = self.get_test_data()

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        text = Text.objects.get(pk=resp_content['id'])

        test_data['title'] = 'a new text title'
        test_data['introduction'] = 'a new introduction'
        test_data['author'] = 'J. K. Idding'

        resp = self.instructor.put('/api/text/{pk}/'.format(pk=text.pk), json.dumps(test_data),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.instructor.get('/api/text/{0}/'.format(text.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertIn('difficulty', resp_content)

        self.assertEquals(resp_content['title'], 'a new text title')
        self.assertEquals(resp_content['introduction'], 'a new introduction')
        self.assertEquals(resp_content['author'], 'J. K. Idding')

        test_data['text_sections'][1]['questions'][0]['body'] = 'A new question?'
        test_data['text_sections'][1]['questions'][0]['answers'][1]['text'] = 'A new answer.'

        resp = self.instructor.put('/api/text/{pk}/'.format(pk=text.pk), json.dumps(test_data),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.instructor.get('/api/text/{0}/'.format(text.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['text_sections'][1]['questions'][0]['body'], 'A new question?')
        self.assertEquals(resp_content['text_sections'][1]['questions'][0]['answers'][1]['text'], 'A new answer.')

    def test_text_lock(self):
        other_instructor_client = self.new_instructor_client(Client())

        resp = self.instructor.post('/api/text/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        resp = self.instructor.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.delete('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.instructor.delete('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.instructor.post('/api/text/{0}/lock/'.format(text.pk), content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_text_correct_answers(self):
        test_data = self.get_test_data()

        for answer in test_data['text_sections'][0]['questions'][0]['answers']:
            answer['correct'] = False

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('textsection_0_question_0_answers', resp_content['errors'])
        self.assertEquals('You must choose a correct answer for this question.',
                          resp_content['errors']['textsection_0_question_0_answers'])

        # set one correct answer
        test_data['text_sections'][0]['questions'][0]['answers'][0]['correct'] = True

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_text_max_char_limits(self):
        test_data = self.get_test_data()
        test_text_section_body_size = 4096

        answer_feedback_limit = Answer._meta.get_field('feedback').max_length

        # answer feedback limited
        test_data['text_sections'][0]['questions'][0]['answers'][0]['feedback'] = 'a' * (answer_feedback_limit + 1)
        # no limit for text section bodies
        test_data['text_sections'][0]['body'] = 'a' * test_text_section_body_size

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('textsection_0_question_0_answer_0_feedback', resp_content['errors'])

        self.assertEquals(resp_content['errors']['textsection_0_question_0_answer_0_feedback'],
                          'Ensure this value has at most '
                          '{0} characters (it has {1}).'.format(answer_feedback_limit, (answer_feedback_limit+1)))

        self.assertNotIn('textsection_0_body', resp_content['errors'])

        test_data['text_sections'][0]['questions'][0]['answers'][0]['feedback'] = 'a'

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertNotIn('errors', resp_content)
        self.assertIn('id', resp_content)

        # ensure db doesn't truncate
        text_section = TextSection.objects.get(pk=resp_content['id'])

        self.assertEquals(len(text_section.body), test_text_section_body_size)

    def test_post_text(self, test_data: Optional[Dict]=None) -> Text:
        test_data = test_data or self.get_test_data()

        num_of_sections = len(test_data['text_sections'])

        resp = self.instructor.post('/api/text/', json.dumps({"malformed": "json"}), content_type='application/json')

        self.assertEquals(resp.status_code, 400)

        resp = self.instructor.post('/api/text/', json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)
        self.assertIn('redirect', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        self.assertEquals(TextSection.objects.count(), num_of_sections)

        resp = self.instructor.get('/api/text/{0}/'.format(text.id), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['title'], test_data['title'])
        self.assertEquals(resp_content['introduction'], test_data['introduction'])
        self.assertEquals(resp_content['tags'], test_data['tags'])

        return text

    def test_delete_text(self):
        resp = self.instructor.post('/api/text/', json.dumps(self.get_test_data()), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.instructor.delete('/api/text/{0}/'.format(resp_content['id']), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertTrue('deleted' in resp_content)

    def generate_text_params(self, sections: List[Dict[AnyStr, int]]) -> Dict:
        section_num = 0
        section_params = []

        for section in sections:
            questions_for_section = [self.gen_text_section_question_params(i)
                                     for i in range(0, section['num_of_questions'])]

            section_params.append(self.gen_text_section_params(section_num, question_params=questions_for_section))

            section_num += 1

        test_data = self.get_test_data(section_params=section_params)

        return test_data

    def gen_question_type(self) -> AnyStr:
        return one_of([just('main_idea'), just('detail')]).example()

    def gen_text_section_question_params(self, order: int) -> Dict:
        return {'body': f'Question {order+1}?',
                'order': order,
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
                  ], 'question_type': self.gen_question_type()}

    def gen_text_section_params(self, order: int, question_params: Optional[List[Dict]]=None) -> Dict:
        return {
            'order': order,
            'body': f'<p style="text-align:center">section {order}</p>\n',
            'questions': question_params or [self.gen_text_section_question_params(order=0)]
         }

    def get_test_data(self, section_params: Optional[List[Dict]]=None) -> Dict:
        return {
            'title': 'text title',
            'introduction': 'an introduction to the text',
            'conclusion': 'a conclusion to the text',
            'tags': ['Sports', 'Science/Technology', 'Other'],
            'author': 'author',
            'source': 'source',
            'text_sections': section_params or [self.gen_text_section_params(0), self.gen_text_section_params(1)]
        }
