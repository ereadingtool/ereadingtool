import collections
import json
from typing import Dict, Optional, List, Tuple

import channels.layers
from asgiref.sync import async_to_sync
from django.test import TestCase
from django.test.client import Client
from statemachine import State

from flashcards.student.session.models import StudentFlashcardSession

from ereadingtool.test.data import TestData
from ereadingtool.test.user import TestUser
from ereadingtool.urls import reverse_lazy
from question.models import Answer
from text.consumers.instructor import ParseTextSectionForDefinitions
from text.models import Text, TextSection
from tag.models import Tag
from text.phrase.models import TextPhrase, TextPhraseTranslation
from text.translations.models import TextWord
from text.yandex.api.definition import (YandexDefinition, YandexDefinitions, YandexDefinitionAPI, YandexTranslations,
                                        YandexTranslation, YandexPhrase)
from text_reading.base import TextReadingNotAllQuestionsAnswered
from text_reading.models import StudentTextReading
from user.student.models import Student


class TestText(TestData, TestUser, TestCase):
    def __init__(self, *args, **kwargs):
        super(TestText, self).__init__(*args, **kwargs)

        self.text_endpoint = reverse_lazy('text-api')

    def setUp(self):
        super(TestText, self).setUp()

        self.instructor = self.new_instructor_client(Client())
        self.student = self.new_student_client(Client())

    def test_definition_objs(self):
        yandex_translation_api = YandexDefinitionAPI()

        definitions = yandex_translation_api.lookup('заявление')

        if definitions:
            self.assertIsInstance(definitions, YandexDefinitions)
            self.assertIsInstance(definitions[0], YandexDefinition)

            if definitions[0].translations:
                self.assertIsInstance(definitions[0].translations, YandexTranslations)
                self.assertIsInstance(definitions[0].translations[0], YandexTranslation)

                yandex_translation = definitions[0].translations[0]

                self.assertIsInstance(yandex_translation.phrase, YandexPhrase)

    def test_parsing_words(self):
        test_data = self.get_test_data()

        test_body = '''<p>Минувшую неделю рубль завершил стремительным укреплением позиций. По данным Московской 
        биржи, курс доллара по итогам торгов пятницы составил 56,25 руб./$, потеряв за неделю более 2 руб. Падение 
        розничных продаж в США снизило вероятность агрессивного повышения ставки в стране и подорвало интерес к 
        американской валюте. Дополнительную поддержку российской валюте оказывают цены на нефть и высокий интерес 
        иностранных инвесторов к ОФЗ (облигации федерального займа).</p>'''

        test_data['text_sections'][0]['body'] = test_body
        test_data['text_sections'][1]['body'] = test_body

        self.create_text(test_data=test_data)

        self.assertTrue(TextSection.objects.count())

        text_section = TextSection.objects.all()[0]

        words = {w: 1 for w in text_section.words}

        self.assertTrue(len(words.keys()))

        self.assertNotIn('2', words)
        self.assertIn('руб', words)

    def test_example_sentence_re(self):
        test_data = self.get_test_data()

        test_body = """Мне 18 лет. Я — студентка Новосибирского пединститута. 
        Две лекции, две пары подряд. Преподаватель немного опаздывает. Так хочется спать…"""

        test_data['text_sections'][0]['body'] = test_body

        self.create_text(test_data=test_data)

        self.assertTrue(TextSection.objects.count())

        text_section = TextSection.objects.all()[0]

        TextPhraseTranslation.create(
            text_phrase=TextWord.create(phrase='опаздывает', instance=0, text_section=text_section.pk),
            phrase='be late',
            correct_for_context=True
        )

        text_phrase = TextPhrase.objects.get(phrase='опаздывает', text_section=text_section)

        self.assertTrue(text_phrase)

        self.assertEquals('Преподаватель немного опаздывает.', text_phrase.sentence)

    def run_definition_background_job(self, test_data: Dict) -> Tuple[int, TextSection]:
        num_of_words = len(test_data['text_sections'][0]['body'].split())

        self.create_text(test_data=test_data)

        # receive one message from the channel layer
        channel_layer = channels.layers.get_channel_layer()

        ret = async_to_sync(channel_layer.receive)('text')

        self.assertTrue(ret)

        # process the message and test the output
        text_parse_consumer = ParseTextSectionForDefinitions(scope=ret)

        text_section, _ = text_parse_consumer.text_section_parse_word_definitions(
            {'text_section_pk': ret['text_section_pk']})

        return num_of_words, text_section

    def test_word_definition_background_job(self):
        test_data = self.get_test_data()

        test_data['text_sections'][0]['body'] = 'заявление неделю'
        test_data['text_sections'][1]['body'] = 'заявление неделю'

        num_of_words, text_section = self.run_definition_background_job(test_data)

        self.assertEquals(text_section.translated_words.count(), num_of_words)

        text_word = text_section.translated_words.all()[0]

        self.assertGreater(text_word.translations.count(), 0)

        text_section_word_translation = text_word.translations.all()[0]

        self.assertTrue(text_section_word_translation.phrase)

    def test_text_reading(self,
                          text: Text = None, student: Student = None, final_state: State = None) -> StudentTextReading:
        test_data = self.get_test_data()

        if not student:
            _, _, student = self.new_student()

        text_obj = text or self.create_text(diff_data=test_data)

        text_sections = text_obj.sections.all()

        text_reading = StudentTextReading.start(student=student, text=text_obj)

        self.assertEquals(text_reading.current_state, text_reading.state_machine.intro)

        # a reading in the introduction state should have a score of 0 / 0
        self.assertDictEqual(text_reading.score, {'num_of_sections': len(text_sections),
                                                  'complete_sections': 0,
                                                  'section_scores': 0,
                                                  'possible_section_scores': 0})

        if final_state == text_reading.state_machine.intro:
            return text_reading

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
        # last answer is always correct
        answer_two = questions[1].answers.all()[3]

        text_reading.answer(answer_two)

        # now we should be able to move on
        text_reading.next()

        self.assertEquals(text_reading.current_state, text_reading.state_machine.in_progress)
        self.assertEquals(text_reading.current_section, text_sections[1])

        if final_state == text_reading.state_machine.in_progress:
            return text_reading

        # and complete
        questions = text_sections[1].questions.all()

        text_reading.answer(questions[0].answers.all()[2])
        text_reading.answer(questions[1].answers.all()[1])

        text_reading.next()

        self.assertEquals(text_reading.current_state, text_reading.state_machine.complete)
        self.assertEquals(text_reading.current_section, None)

        self.assertTrue(text_reading.end_dt)

        total_num_of_questions = sum(len(section['questions']) for section in test_data['text_sections'])
        score = text_reading.score

        self.assertDictEqual(score, {'num_of_sections': len(text_sections),
                                     'complete_sections': len(text_sections),
                                     'section_scores': 1,
                                     'possible_section_scores': total_num_of_questions})

        if final_state:
            self.assertEquals(text_reading.current_state, final_state)

        return text_reading

    def test_set_difficulty(self):
        text = self.create_text(diff_data={'difficulty': 'advanced_mid'})

        self.assertEquals(text.difficulty.slug, 'advanced_mid')

        text = self.create_text(diff_data={'difficulty': 'intermediate_high'})

        self.assertEquals(text.difficulty.slug, 'intermediate_high')

    def test_text_tags(self):
        test_data = self.get_test_data()

        text_one = self.create_text()
        text_two = self.create_text(diff_data={'tags': ['Society and Societal Trends']})

        resp = self.instructor.put(reverse_lazy('text-tag-api', kwargs={'pk': text_one.pk}),
                                   json.dumps('Society and Societal Trends'),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), len(test_data['tags'])+1)

        self.assertIn('Society and Societal Trends', [tag.name for tag in text_one.tags.all()])

        resp = self.instructor.put(reverse_lazy('text-tag-api', kwargs={'pk': text_one.pk}),
                                   json.dumps(['Sports', 'Science/Technology', 'Other']),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 4)

        resp = self.instructor.delete(reverse_lazy('text-tag-api', kwargs={'pk': text_one.pk}),
                                      json.dumps('Other'),
                                      content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(text_one.tags.count(), 3)
        self.assertEquals(text_two.tags.count(), 1)

        resp = self.instructor.delete(reverse_lazy('text-tag-api', kwargs={'pk': text_two.pk}),
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

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        text_id = resp_content['id']

        test_data['text_sections'].append(self.gen_text_section_params(2))

        resp = self.instructor.put(reverse_lazy('text-item-api', kwargs={'pk': text_id}),
                                   json.dumps(test_data),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        text = Text.objects.get(pk=text_id)

        self.assertEquals(3, text.sections.count())

    def test_filter_text_by_status(self):
        user = Student.objects.get()
        state_cls = StudentTextReading.state_machine_cls

        text = collections.OrderedDict()

        text['intro'] = self.create_text(diff_data={'title': 'stopped at intro',
                                                    'tags': ['Other']})
        text_one_reading = self.test_text_reading(text['intro'], user, state_cls.intro)

        text['in_progress'] = self.create_text(diff_data={'title': 'stopped at in_progress',
                                                          'tags': ['Economics/Business', 'Medicine/Health Care']})
        text_two_reading = self.test_text_reading(text['in_progress'], user, state_cls.in_progress)

        text['read'] = self.create_text(diff_data={'title': 'stopped at complete', 'tags': ['Sports']})
        text_three_reading = self.test_text_reading(text['read'], user, state_cls.complete)

        text['unread'] = self.create_text(diff_data={'title': 'unread', 'tags': ['Science/Technology']})

        def test_status(statuses, expected_texts: List, addl_filters: List[Tuple] = None):
            if addl_filters is None:
                addl_filters = list()

            status_search = '&'.join([f'status={status}' for status in statuses])

            addl_search = '&'.join([f'{k}={v}' for (k, v) in addl_filters])

            resp = self.student.get(f'/api/text/?{status_search}&{addl_search}')

            self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

            resp_content = json.loads(resp.content.decode('utf8'))

            if not expected_texts:
                self.assertEquals(set([txt['title'] for txt in resp_content]), set(expected_texts))
            else:
                self.assertSetEqual(set([txt['title'] for txt in resp_content]),
                                    set([txt.title for txt in expected_texts]))

        # test other filters will work with a status filter
        test_status({'unread'}, [
            text['unread']
        ], addl_filters=[('tag', 'Science/Technology'), ('difficulty', 'intermediate_mid')])

        test_status({'read'}, [], addl_filters=[('tag', 'Science/Technology'), ('difficulty', 'intermediate_mid')])

        # enumerate these combinations for now but we can break out hypothesis if it becomes unmanageable

        # set of all texts
        test_status({'unread', 'read', 'in_progress'}, [
            text for text in text.values()
        ])

        # unread
        test_status({'unread'}, [
            text['unread']
        ])

        # unread and in_progress
        test_status({'unread', 'in_progress'},
                    [text['intro'],
                     text['in_progress'],
                     text['unread']])

        # read and in_progress
        test_status({'read', 'in_progress'}, [
            text['read'],
            text['intro'],
            text['in_progress']
        ])

        # read and unread
        test_status({'read', 'unread'}, [
            text['read'],
            text['unread']
        ])

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

        self.assertListEqual(resp_content, [student.to_text_summary_dict(text_one),
                                            student.to_text_summary_dict(text_two)])

    def test_put_text(self):
        test_data = self.get_test_data()

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        text = Text.objects.get(pk=resp_content['id'])

        test_data['title'] = 'a new text title'
        test_data['introduction'] = 'a new introduction'
        test_data['author'] = 'J. K. Idding'

        resp = self.instructor.put(reverse_lazy('text-item-api', kwargs={'pk': text.pk}), json.dumps(test_data),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.instructor.get(reverse_lazy('text-item-api', kwargs={'pk': text.id}),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertIn('difficulty', resp_content)

        self.assertEquals(resp_content['title'], 'a new text title')
        self.assertEquals(resp_content['introduction'], 'a new introduction')
        self.assertEquals(resp_content['author'], 'J. K. Idding')

        test_data['text_sections'][1]['questions'][0]['body'] = 'A new question?'
        test_data['text_sections'][1]['questions'][0]['answers'][1]['text'] = 'A new answer.'

        resp = self.instructor.put(reverse_lazy('text-item-api', kwargs={'pk': text.pk}), json.dumps(test_data),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        resp = self.instructor.get(reverse_lazy('text-item-api', kwargs={'pk': text.id}),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['text_sections'][1]['questions'][0]['body'], 'A new question?')
        self.assertEquals(resp_content['text_sections'][1]['questions'][0]['answers'][1]['text'], 'A new answer.')

    def test_text_lock(self):
        other_instructor_client = self.new_instructor_client(Client())

        resp = self.instructor.post(reverse_lazy('text-api'),
                                    json.dumps(self.get_test_data()),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        lock_api_endpoint_for_text = reverse_lazy('text-lock-api', kwargs={'pk': text.pk})

        resp = self.instructor.post(reverse_lazy('text-lock-api', kwargs={'pk': text.pk}),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post(lock_api_endpoint_for_text, content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.delete(lock_api_endpoint_for_text, content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.instructor.delete(lock_api_endpoint_for_text, content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = other_instructor_client.post(lock_api_endpoint_for_text, content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp = self.instructor.post(lock_api_endpoint_for_text, content_type='application/json')

        self.assertEquals(resp.status_code, 500, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_text_correct_answers(self):
        test_data = self.get_test_data()

        for answer in test_data['text_sections'][0]['questions'][0]['answers']:
            answer['correct'] = False

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('textsection_0_question_0_answers', resp_content['errors'])
        self.assertEquals('You must choose a correct answer for this question.',
                          resp_content['errors']['textsection_0_question_0_answers'])

        # set one correct answer
        test_data['text_sections'][0]['questions'][0]['answers'][0]['correct'] = True

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

    def test_post_text_max_char_limits(self):
        test_data = self.get_test_data()
        test_text_section_body_size = 4096

        answer_feedback_limit = Answer._meta.get_field('feedback').max_length

        # answer feedback limited
        test_data['text_sections'][0]['questions'][0]['answers'][0]['feedback'] = 'a' * (answer_feedback_limit + 1)
        # no limit for text section bodies
        test_data['text_sections'][0]['body'] = 'a' * test_text_section_body_size

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 400, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('errors', resp_content)
        self.assertIn('textsection_0_question_0_answer_0_feedback', resp_content['errors'])

        self.assertEquals(resp_content['errors']['textsection_0_question_0_answer_0_feedback'],
                          'Ensure this value has at most '
                          '{0} characters (it has {1}).'.format(answer_feedback_limit, (answer_feedback_limit+1)))

        self.assertNotIn('textsection_0_body', resp_content['errors'])

        test_data['text_sections'][0]['questions'][0]['answers'][0]['feedback'] = 'a'

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertNotIn('errors', resp_content)
        self.assertIn('id', resp_content)

        # ensure db doesn't truncate
        text_section = TextSection.objects.get(pk=resp_content['id'])

        self.assertEquals(len(text_section.body), test_text_section_body_size)

    def create_text(self, test_data: Dict = None, diff_data: Dict = None) -> Text:
        text_data = test_data or self.get_test_data()

        if diff_data:
            text_data.update(diff_data)

        resp = self.instructor.post(reverse_lazy('text-api'),
                                    json.dumps(text_data),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        text = Text.objects.get(pk=resp_content['id'])

        return text

    def test_post_text(self, test_data: Optional[Dict] = None) -> Text:
        test_data = test_data or self.get_test_data()

        num_of_sections = len(test_data['text_sections'])

        resp = self.instructor.post(reverse_lazy('text-api'),
                                    json.dumps({"malformed": "json"}),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 400)

        resp = self.instructor.post(reverse_lazy('text-api'), json.dumps(test_data), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)
        self.assertIn('redirect', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        self.assertEquals(TextSection.objects.count(), num_of_sections)

        resp = self.instructor.get(reverse_lazy('text-item-api', kwargs={'pk': text.id}),
                                   content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertEquals(resp_content['title'], test_data['title'])
        self.assertEquals(resp_content['introduction'], test_data['introduction'])
        self.assertEquals(resp_content['tags'], test_data['tags'])

        return text

    def test_delete_text(self, text: Optional[Text] = None):
        if text is None:
            text = self.create_text()

        resp = self.instructor.delete(reverse_lazy('text-item-api', kwargs={'pk': text.pk}),
                                      content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertTrue(resp_content)

        self.assertTrue('deleted' in resp_content)

    def test_delete_text_with_one_student_flashcard(self):
        test_data = self.get_test_data()

        test_data['text_sections'][0]['body'] = 'заявление неделю Число'

        text = self.create_text(test_data=test_data)

        text_sections = text.sections.all()

        заявление = TextWord.create(phrase='заявление', instance=0, text_section=text_sections[0].pk)

        TextPhraseTranslation.create(
            text_phrase=заявление,
            phrase='statement',
            correct_for_context=True
        )

        test_student = Student.objects.filter()[0]

        test_student.add_to_flashcards(заявление)

        student_flashcard_session, _ = StudentFlashcardSession.objects.get_or_create(student=test_student)

        text.delete()

        # session is deleted if there's a single flashcard
        self.assertFalse(StudentFlashcardSession.objects.filter(pk=student_flashcard_session.pk).exists())

    def test_delete_text_with_multiple_student_flashcards(self):
        test_data_one = self.get_test_data()
        test_data_two = self.get_test_data()

        test_data_one['text_sections'][0]['body'] = 'заявление'
        test_data_two['text_sections'][0]['body'] = 'неделю'

        text_one = self.create_text(test_data=test_data_one)
        text_two = self.create_text(test_data=test_data_two)

        text_one_section = text_one.sections.all()
        text_two_section = text_two.sections.all()

        заявление = TextWord.create(phrase='заявление', instance=0, text_section=text_one_section[0].pk)
        неделю = TextWord.create(phrase='неделю', instance=0, text_section=text_two_section[0].pk)

        TextPhraseTranslation.create(
            text_phrase=заявление,
            phrase='statement',
            correct_for_context=True
        )

        TextPhraseTranslation.create(
            text_phrase=неделю,
            phrase='a week',
            correct_for_context=True
        )

        test_student = Student.objects.filter()[0]

        test_student.add_to_flashcards(заявление)
        test_student.add_to_flashcards(неделю)

        student_flashcard_session, _ = StudentFlashcardSession.objects.get_or_create(student=test_student)

        text_one.delete()

        # session isn't deleted if there's more than one flashcard
        self.assertTrue(StudentFlashcardSession.objects.filter(pk=student_flashcard_session.pk).exists())

        student_flashcard_session.refresh_from_db()

        self.assertTrue(student_flashcard_session.current_flashcard)

        self.assertTrue(student_flashcard_session.current_flashcard.phrase, неделю)
