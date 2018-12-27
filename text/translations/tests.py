import json

from django.test import TestCase

from ereadingtool.urls import reverse_lazy

from tag.models import Tag
from text.models import TextDifficulty
from django.test.client import Client

from text.models import Text

from text.translations.models import TextWord, TextWordTranslation

from text.tests import TestText
from ereadingtool.test.user import TestUser


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
            reverse_lazy('text-translation-merge-method'),
            json.dumps({
                'text_word_ids': [test_text_word.pk],
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
