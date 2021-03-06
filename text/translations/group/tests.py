import os
import json

from typing import List
from django.test import TestCase

from django.urls import reverse

from tag.models import Tag
from text.models import TextDifficulty
from django.test.client import Client

from text.models import Text

from text.translations.models import TextWord

from text.tests import TestText
from ereadingtool.test.user import TestUser


class TestTextWordGroup(TestUser, TestCase):
    def __init__(self, *args, **kwargs):
        super(TestTextWordGroup, self).__init__(*args, **kwargs)

        self.text_group_endpoint = reverse('text-word-group-api')
        self.text_group_item_endpoint = lambda group: reverse('text-word-group-api', kwargs={'textphrase_ptr_id': group.pk})

        self.test_text_data = TestText.get_test_data()
        self.text = None

    def setUp(self):
        super(TestTextWordGroup, self).setUp()

        Tag.setup_default()
        TextDifficulty.setup_default()

        self.instructor = self.new_instructor_client(Client())
        self.student = self.new_student_client(Client())

        resp = self.instructor.post(reverse('text-api'),
                                    json.dumps(self.test_text_data),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.text = Text.objects.get(pk=resp_content['id'])

    def test_remove_grouping(self):

        text_words = self.test_create_grouped_words()

        text_group = text_words[0].group_word.group

        resp = self.instructor.delete(self.text_group_item_endpoint(text_group))

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertEquals(resp_content['deleted'], True)

    def test_create_grouped_words(self) -> List[TextWord]:
        section = self.text.sections.all()[0]

        Post = TextWord.objects.create(
            phrase='Post',
            text_section=section
        )

        Office = TextWord.objects.create(
            phrase='Office',
            text_section=section
        )

        resp = self.instructor.post(self.text_group_endpoint,
                                    json.dumps([Post.pk, Office.pk]),
                                    content_type='application/json')

        self.assertEquals(resp.status_code, 200, json.dumps(json.loads(resp.content.decode('utf8')), indent=4))

        resp_content = json.loads(resp.content.decode('utf8'))

        self.assertEquals(resp_content['grouped'], True)

        Post.refresh_from_db()
        Office.refresh_from_db()

        self.assertTrue(Post.group_word)
        self.assertTrue(Office.group_word)

        return [Post, Office]
