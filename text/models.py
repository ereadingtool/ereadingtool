from typing import Optional, List, Dict

from django.db import models
from mixins.model import Timestamped, WriteLockable, WriteLocked
from tag.models import Taggable

from text.translations.mixins import TextSectionDefinitionsMixin
from text.managers import TextWithStudentReadingsManager, TextWithInstructorReadingsManager

from django.urls import reverse

text_statuses = [
    ('unread', 'Unread'),
    ('in_progress', 'In Progress'),
    ('read', 'Read'),
]


class TextDifficulty(models.Model):
    class Meta:
        verbose_name_plural = 'Text Difficulties'

    slug = models.SlugField(blank=False)
    name = models.CharField(max_length=255, blank=False)

    def __str__(self):
        return self.name

    def to_dict(self):
        return {
            'slug': self.slug,
            'name': self.name
        }

    @classmethod
    def difficulty_keys(cls):
        return [difficulty.slug for difficulty in cls.objects.all()]

    @classmethod
    def setup_default(cls):
        for params in [('intermediate_mid', 'Intermediate-Mid'), ('intermediate_high', 'Intermediate-High'),
                       ('advanced_low', 'Advanced-Low'), ('advanced_mid', 'Advanced-Mid')]:
            difficulty, created = TextDifficulty.objects.get_or_create(slug=params[0], name=params[1])

            if created:
                difficulty.save()


class Text(Taggable, WriteLockable, Timestamped, models.Model):
    objects = models.Manager()
    objects_with_student_readings = TextWithStudentReadingsManager()
    objects_with_instructor_readings = TextWithInstructorReadingsManager()

    introduction = models.CharField(max_length=512, null=False, blank=False)

    title = models.CharField(max_length=255, null=False, blank=False)
    source = models.CharField(max_length=255, blank=False)
    difficulty = models.ForeignKey(TextDifficulty, null=True, related_name='texts', on_delete=models.SET_NULL)
    author = models.CharField(max_length=255, blank=True)

    conclusion = models.CharField(max_length=2000, null=True, blank=True)

    created_by = models.ForeignKey('user.Instructor', null=True, on_delete=models.SET_NULL,
                                   related_name='created_texts')
    last_modified_by = models.ForeignKey('user.Instructor', null=True, on_delete=models.SET_NULL,
                                         related_name='last_modified_text')
    rating = models.IntegerField(default=0)

    @property
    def words(self):
        return {
            text_phrase.phrase: {
                'grammemes': text_phrase.serialized_grammemes,
                'translations': [translation.phrase for translation in
                                 text_phrase.translations.all()]
            }
            for section in self.sections.prefetch_related('translated_words').all()
            for text_phrase in section.translated_words.all()
        }

    @property
    def text_words(self):
        # for the entire text, compile an array of dictionaries, indexed by section number
        section_words = []

        # translated_words__translations joins TextSections with TextPhrase and their TextPhraseTranslations
        for section in self.sections.prefetch_related('translated_words__translations').order_by('order').all():
            words = dict()

            for text_phrase in section.translated_words.all():
                phrase = text_phrase.phrase.lower()

                words.setdefault(phrase, [])

                words[phrase].append(text_phrase.child_instance.to_translations_dict())

            section_words.append(words)

        return section_words

    @classmethod
    def to_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'introduction': {'type': 'string'},
                'title': {'type': 'string'},
                'source': {'type': 'string'},
                'difficulty': {'type': 'string', 'enum': [''] + TextDifficulty.difficulty_keys()},
                'author': {'type': 'string'},
                'text_sections': {'type': 'array', 'items': TextSection.to_json_schema()},
                'tags': {
                    'type': 'array',
                    'items': {
                        'type': 'string',
                        'enum': [tag.name for tag in cls.tag_choices()]
                    }
                },
                'conclusion': {'type': 'string'},
            },
            'required': ['introduction', 'title', 'source', 'author', 'text_sections', 'tags']
        }

        return schema

    @classmethod
    def update(cls, text_params: Dict, text_sections_params: Dict) -> 'Text':
        if text_params['text'].write_locked:
            raise WriteLocked

        text = text_params['form'].save()
        text.save()

        for section_params in text_sections_params.values():
            text_section = section_params['text_section_form'].save(commit=False)
            text_section.text = text
            text_section.save()

            if section_params['instance']:
                text_section.update_definitions_if_new(
                    old_body=section_params['text_section_form'].cleaned_data['body'])

            # Need to freshen up the answers. Delete them all and re-add them.
            text_section.questions.all().delete()

            for i, question in enumerate(section_params['questions']):
                question_obj = question['form'].save(commit=False)

                question_obj.text_section = text_section
                question_obj.order = i
                question_obj.save()

                for j, answer_form in enumerate(question['answer_forms']):
                    answer = answer_form.save(commit=False)

                    answer.question = question_obj
                    answer.order = j
                    answer.save()

        return text

    @classmethod
    def create(cls, text_params: Dict, text_sections_params: Dict) -> 'Text':
        text = text_params['form'].save()
        text.save()

        for section_params in text_sections_params.values():
            text_section = section_params['text_section_form'].save(commit=False)
            text_section.text = text
            text_section.save()

            text_section.update_definitions()

            for i, question in enumerate(section_params['questions']):
                question_obj = question['form'].save(commit=False)

                question_obj.text_section = text_section
                question_obj.order = i
                question_obj.save()

                for j, answer_form in enumerate(question['answer_forms']):
                    answer = answer_form.save(commit=False)

                    answer.question = question_obj
                    answer.order = j
                    answer.save()

        return text

    def to_summary_dict(self) -> Dict:
        text_dict = self.to_dict_meta()

        text_dict['rating'] = self.rating
        text_dict['text_section_count'] = self.sections.count()
        text_dict['translation_service_processed'] = all([ts.translation_service_processed == 1 for ts in self.sections.all()])

        return text_dict

    def to_student_summary_dict(self) -> Dict:
        text_summary_dict = self.to_summary_dict()

        return text_summary_dict

    def to_instructor_summary_dict(self) -> Dict:
        text_summary_dict = self.to_summary_dict()

        text_summary_dict['edit_uri'] = reverse('text-edit', kwargs={'pk': self.pk})

        return text_summary_dict

    def to_text_reading_dict(self) -> Dict:
        text_dict = self.to_dict()

        del text_dict['words']
        del text_dict['write_locker']

        text_dict['text_sections'] = list(map(lambda section: section.to_text_reading_dict(), self.sections.all()))
        return text_dict

    def to_dict(self, text_sections: Optional[List] = None) -> Dict:
        return {
            'id': self.pk,
            'title': self.title,
            'introduction': self.introduction,
            'conclusion': self.conclusion,
            'author': self.author,
            'source': self.source,
            'difficulty': self.difficulty.slug,
            'created_by': str(self.created_by),
            'last_modified_by': str(self.last_modified_by) if self.last_modified_by else None,
            'tags': [tag.name for tag in self.tags.all()],
            'modified_dt': self.modified_dt.isoformat(),
            'created_dt': self.created_dt.isoformat(),
            'text_sections': [text_section.to_dict() for text_section in
                              (text_sections if text_sections else self.sections.all())],
            'translation_service_processed': all([text_section.translation_service_processed == 1 for text_section in
                              (text_sections if text_sections else self.sections.all())]),
            'words': self.words,
            'write_locker': str(self.write_locker) if self.write_locker else None
        }

    def __str__(self):
        return self.title

    # TODO: uri
    def to_dict_meta(self, text_sections: Optional[List] = None) -> Dict:
        return {
            'id': self.pk,
            'title': self.title,
            'author': self.author,
            'difficulty': self.difficulty.slug,
            'created_by': str(self.created_by),
            'tags': [tag.name for tag in self.tags.all()],
            'modified_dt': self.modified_dt.isoformat(),
            'created_dt': self.created_dt.isoformat(),
        }

    def delete(self, *args, **kwargs):
        if self.is_locked():
            raise WriteLocked

        super(Text, self).delete(*args, **kwargs)


class TextSection(TextSectionDefinitionsMixin, Timestamped, models.Model):
    text = models.ForeignKey(Text, related_name='sections', on_delete=models.CASCADE)

    order = models.IntegerField()
    body = models.TextField()
    translation_service_processed = models.IntegerField(default=0)

    @classmethod
    def to_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'order': {'type': 'integer'},
                'body': {'type': 'string'},
                'questions': {'type': 'array', 'items': {
                    'type': 'object',
                    'properties': {
                        'body': {'type': 'string'},
                        'order': {'type': 'integer'},
                        'question_type': {'type': 'string', 'enum': ['main_idea', 'detail']},
                        'answer': {'type': 'array', 'items': {
                            'properties': {
                                'order': {'type': 'integer'},
                                'text': {'type': 'string'},
                                'correct': {'type': 'boolean'},
                                'feedback': {'type': 'string'}
                            },
                            'required': ['text', 'correct', 'feedback']}
                        }
                    },
                    'required': ['body', 'question_type', 'answers']}
                }
            },
            'required': ['body', 'questions']
        }

        return schema

    def to_text_reading_dict(self, text_reading=None, *args, **kwargs) -> Dict:
        questions_text_reading_dicts = [question.to_text_reading_dict(text_reading)
                                        for question in self.questions.all()]

        questions_count = len((list(questions_text_reading_dicts)))

        phrases = dict()

        for text_phrase in self.translated_words.prefetch_related('translations').filter():
            phrases.setdefault(text_phrase.phrase, [])

            text_word_dict = text_phrase.child_instance.to_translations_dict()

            # students dont need to know about endpoints
            if 'endpoints' in text_word_dict:
                del text_word_dict['endpoints']

            phrases[text_phrase.phrase].append(text_word_dict)

        text_section_dict = {
            'order': self.order,
            'created_dt': self.created_dt.isoformat(),
            'modified_dt': self.modified_dt.isoformat(),
            'question_count': questions_count,
            'questions': questions_text_reading_dicts,
            'body': self.body,
            'translations': phrases
        }

        text_section_dict.update(**kwargs)

        return text_section_dict

    def to_dict(self) -> Dict:
        questions = [question.to_dict() for question in self.questions.all()]
        questions_count = len(list(questions))

        return {
            'id': self.pk,
            'order': self.order,
            'created_dt': self.created_dt.isoformat(),
            'modified_dt': self.modified_dt.isoformat(),
            'question_count': questions_count,
            'questions': questions,
            'body': self.body,
        }

    def __str__(self):
        return f'Text Section {self.order} of {self.text.title}'


class TextRating(models.Model):
    class Meta:
        verbose_name_plural = 'Text Ratings'
        unique_together = (('student', 'text', 'vote'))

    student = models.ForeignKey('user.Student', null=False, on_delete=models.CASCADE, related_name='text_ratings')
    text = models.ForeignKey(Text, on_delete=models.CASCADE, related_name='texts')
    vote = models.IntegerField(default=0)
