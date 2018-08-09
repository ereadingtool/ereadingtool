from typing import Dict, TypeVar

from django.db import models
from text.models import Text, TextSection, TextDifficulty
from user.models import ReaderUser


class Student(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    difficulty_preference = models.ForeignKey(TextDifficulty, null=True, on_delete=models.SET_NULL,
                                              related_name='students')

    def to_dict(self):
        difficulties = [(text_difficulty.slug, text_difficulty.name)
                        for text_difficulty in TextDifficulty.objects.all()]

        # difficulty_preference can be null
        difficulties.append(('', ''))

        return {
            'id': self.pk,
            'username': self.user.username,
            'difficulty_preference': [self.difficulty_preference.slug, self.difficulty_preference.name]
            if self.difficulty_preference else None,
            'difficulties': difficulties
        }

    def __str__(self):
        return self.user.username


class StudentProgress(models.Model):
    student = models.ForeignKey(Student, null=False, related_name='progress', on_delete=models.CASCADE)

    text_section = models.ForeignKey(TextSection, null=False, related_name='student_progress',
                                     on_delete=models.SET_NULL)

    complete = models.BooleanField(null=True)

    class Meta:
        unique_together = (('student', 'text_section'),)

    @classmethod
    def completed(cls, student: Student, section: TextSection) -> TypeVar('StudentProgress'):
        progress = StudentProgress.objects.create(student=student, text_section=section, complete=True)

        progress.save()

        return progress

    @classmethod
    def to_json_schema(cls) -> Dict:
        schema = {
            'type': 'object',
            'properties': {
                'section_complete': {'type': 'int'},
            },
            'required': ['section_complete']
        }

        return schema
