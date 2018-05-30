from django.db import models
from typing import TypeVar, Optional
from mixins.model import Timestamped, WriteLockable, WriteLocked


class Quiz(WriteLockable, Timestamped, models.Model):
    title = models.CharField(max_length=255, null=False, blank=False)
    last_modified_by = models.ForeignKey('user.Instructor', null=True, on_delete=models.SET_NULL,
                                         related_name='last_modified_quiz')

    @classmethod
    def update(cls, quiz_params: dict, text_params: dict) -> TypeVar('Quiz'):
        if quiz_params['quiz'].write_locked:
            raise WriteLocked

        quiz = quiz_params['form'].save()
        quiz.save()

        for text_param in text_params.values():
            text = text_param['text_form'].save(commit=False)
            text.quiz = quiz
            text.save()

            for i, question in enumerate(text_param['questions']):
                question_obj = question['form'].save(commit=False)

                question_obj.text = text
                question_obj.order = i
                question_obj.save()

                for j, answer_form in enumerate(question['answer_forms']):
                    answer = answer_form.save(commit=False)

                    answer.question = question_obj
                    answer.order = j
                    answer.save()

        return quiz

    @classmethod
    def create(cls, text_params: dict, quiz_params: dict) -> TypeVar('Quiz'):
        quiz = Quiz.objects.create(**quiz_params['form'].data)
        quiz.save()

        for text_param in text_params.values():
            text = text_param['text_form'].save(commit=False)
            text.quiz = quiz
            text.save()

            for i, question in enumerate(text_param['questions']):
                question_obj = question['form'].save(commit=False)

                question_obj.text = text
                question_obj.order = i
                question_obj.save()

                for j, answer_form in enumerate(question['answer_forms']):
                    answer = answer_form.save(commit=False)

                    answer.question = question_obj
                    answer.order = j
                    answer.save()

        return quiz

    def to_summary_dict(self) -> dict:
        return {
            'id': self.pk,
            'title': self.title,
            'modified_dt': self.modified_dt.isoformat(),
            'created_dt': self.created_dt.isoformat(),
            'text_count': self.texts.count(),
            'write_locker': str(self.write_locker) if self.write_locker else None
        }

    def to_dict(self, texts: Optional[list]=None) -> dict:
        return {
            'id': self.pk,
            'title': self.title,
            'modified_dt': self.modified_dt.isoformat(),
            'created_dt': self.created_dt.isoformat(),
            'texts': [text.to_dict() for text in (texts if texts else self.texts.all())],
            'write_locker': str(self.write_locker) if self.write_locker else None
        }

    def __str__(self):
        return self.title
