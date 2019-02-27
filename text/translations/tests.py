import json

from django.test import TestCase
from django.urls import reverse

from ereadingtool.urls import reverse_lazy

from tag.models import Tag
from text.models import TextDifficulty
from django.test.client import Client

from text.models import Text

from text.translations.models import TextWord, TextWordTranslation

from text.tests import TestText
from ereadingtool.test.user import TestUser


class TestTextWord(TestUser, TestCase):
    def __init__(self, *args, **kwargs):
        super(TestTextWord, self).__init__(*args, **kwargs)

        self.test_text_data = TestText.get_test_data()
        self.text = None

    def setUp(self):
        super(TestTextWord, self).setUp()

        Tag.setup_default()
        TextDifficulty.setup_default()

        self.instructor = self.new_instructor_client(Client())
        self.student = self.new_student_client(Client())

    def setup_text(self, test_data) -> Text:
        resp = self.instructor.post(reverse_lazy('text-api'),
                                    json.dumps(test_data),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        self.assertEquals(Text.objects.count(), 1)

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)

        text = Text.objects.get(pk=resp_content['id'])

        return text

    def test_text_compound_words(self):
        text_word_group_api_endpoint = reverse('text-word-group-api')
        test_data = TestText.get_test_data()

        test_data['text_sections'][0]['body'] += 'Post Office is a compound word.'

        text = self.setup_text(test_data)

        text_section_one = text.sections.all()[0]

        text_words = [
            TextWord.objects.create(text_section=text_section_one, instance=0, word='Post').pk,
            TextWord.objects.create(text_section=text_section_one, instance=0, word='Office').pk,
        ]

        resp = self.instructor.post(text_word_group_api_endpoint,
                                    json.dumps(text_words), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('grouped', resp_content)
        self.assertTrue(resp_content['grouped'])

    def test_add_text_word_to_text_section(self):
        text_word_api_endpoint = reverse('text-word-api')
        test_data = TestText.get_test_data()

        test_data['text_sections'][0]['body'] += 'A test sentence.'

        text = self.setup_text(test_data)

        text_section_one = text.sections.all()[0]

        resp = self.instructor.post(text_word_api_endpoint,
                                    json.dumps({
                                        'text_section': text_section_one.pk,
                                        'instance': 0,
                                        'word': 'sentence'
                                    }), content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertIn('id', resp_content)


class TestTextWordTranslations(TestUser, TestCase):
    def __init__(self, *args, **kwargs):
        super(TestTextWordTranslations, self).__init__(*args, **kwargs)

        self.test_text_data = TestText.get_test_data()
        self.text = None

    def setUp(self):
        super(TestTextWordTranslations, self).setUp()

        Tag.setup_default()
        TextDifficulty.setup_default()

        self.instructor = self.new_instructor_client(Client())
        self.student = self.new_student_client(Client())

        resp = self.instructor.post(reverse_lazy('text-api'),
                                    json.dumps(self.test_text_data),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.text = Text.objects.get(pk=resp_content['id'])

    def test_translations_merge(self):
        # mock text word since we don't necessarily want to get into running translations code in this particular test
        test_text_word = TextWord.objects.create(
            word='something',
            text_section=self.text.sections.all()[0]
        )

        resp = self.instructor.put(
            reverse_lazy('text-translation-match-method'),
            json.dumps({
                'words': [{'id': test_text_word.pk, 'word_type': 'single'}],
                'translations': [
                    {'correct_for_context': True, 'phrase': 'stuff'},
                    {'correct_for_context': False, 'phrase': 'stuff 2'},
                    {'correct_for_context': False, 'phrase': 'stuff 3'}
                ]}
            )
        )

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        translations = TextWordTranslation.objects.filter(word=test_text_word)

        self.assertEquals(len(translations), 3)
