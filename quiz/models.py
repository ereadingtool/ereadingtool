from django.db import models
from typing import TypeVar, Optional


class Quiz(models.Model):
    title = models.CharField(max_length=255, null=False, blank=False)

    @classmethod
    def create(cls, text_params: dict, **quiz_params: dict) -> TypeVar('Quiz'):
        quiz = Quiz.objects.create(**quiz_params)
        quiz.save()

        texts = []

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

            texts.append(text)

        return quiz

    def to_dict(self, texts: Optional[list]) -> dict:
        return {
            'title': self.title,
            'texts': [text.to_dict() for text in (texts if texts else self.texts.objects.all())]
        }
