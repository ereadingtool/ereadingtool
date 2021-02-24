from typing import Dict, AnyStr, Optional, List, Tuple

from django.test import TestCase

from tag.models import Tag
from text.models import TextDifficulty

from hypothesis.strategies import just, one_of


class TestData(TestCase):
    def __init__(self, *args, **kwargs):
        super(TestData, self).__init__(*args, **kwargs)

    def setUp(self) -> None:
        super(TestData, self).setUp()

        Tag.setup_default()
        TextDifficulty.setup_default()

    @classmethod
    def gen_text_section_params(cls, order: int, question_params: Optional[List[Dict]] = None) -> Dict:
        return {
            'order': order,
            'body': f'<p style="text-align:center">section {order}</p>\n',
            'questions': question_params or [cls.gen_text_section_question_params(order=0),
                                             cls.gen_text_section_question_params(order=1)]
        }

    @classmethod
    def get_test_data(cls, section_params: Optional[List[Dict]] = None) -> Dict:
        return {
            'title': 'text title',
            'introduction': 'an introduction to the text',
            'difficulty': 'intermediate_mid',
            'conclusion': 'a conclusion to the text',
            'tags': ['Sports', 'Science/Technology', 'Other'],
            'author': 'author',
            'source': 'source',
            'text_sections': section_params or [cls.gen_text_section_params(0), cls.gen_text_section_params(1)]
        }

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

    @classmethod
    def gen_question_type(cls) -> AnyStr:
        return one_of([just('main_idea'), just('detail')]).example()

    @classmethod
    def gen_text_section_question_params(cls, order: int) -> Dict:
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
                ], 'question_type': cls.gen_question_type()}

    def add_questions_to_test_data(self, test_data: Dict, section: int, num_of_questions: int) -> Dict:
        first_question = test_data['text_sections'][section]['questions'][0]
        end_index = first_question['order'] + 1 + num_of_questions

        for i in range(first_question['order']+1, end_index):
            test_data['text_sections'][section]['questions'].append(self.gen_text_section_question_params(order=i))

        return test_data
