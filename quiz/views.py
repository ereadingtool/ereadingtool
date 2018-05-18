import json

from django.views.generic import TemplateView
from user.views.mixin import ProfileView
from mixins.view import ElmLoadJsView
from text.models import TextDifficulty, Text
from django.db.models import ObjectDoesNotExist
from django.db import IntegrityError

from django.core.exceptions import ValidationError
from typing import TypeVar


from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import View
from django.http import HttpResponse

from question.forms import QuestionForm, AnswerForm
from text.forms import TextForm, ModelForm

from quiz.models import Quiz


class QuizView(ProfileView, TemplateView):
    login_url = reverse_lazy('student-login')
    template_name = 'quiz.html'

    model = Quiz


class QuizLoadElm(ElmLoadJsView):
    def get_context_data(self, **kwargs):
        context = super(QuizLoadElm, self).get_context_data(**kwargs)

        context['elm']['quiz_id'] = {'quote': False, 'safe': True, 'value': context['pk']}

        return context


class QuizAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('student-login')

    model = Quiz

    @classmethod
    def form_validation_errors(cls, errors: dict, parent_key: str, form: ModelForm) -> dict:
        for k in form.errors.keys():
            errors['_'.join([parent_key, k])] = str(form.errors[k].data[0].message)

        return errors

    @classmethod
    def validate_text_params(cls, text_params: TypeVar('list(dict)')) -> (dict, dict):
        new_text_params = {}
        errors = {}

        for i, text_param in enumerate(text_params):
            new_text_params, errors = QuizAPIView.validate_text_param(
                text_param=text_param,
                order=i,
                errors=errors,
                output_params=new_text_params)

        return new_text_params, errors

    @classmethod
    def validate_question_param(cls, text_key: str, question_param: dict, errors: dict) -> (list, dict):
        questions = []

        for i, question_param in enumerate(question_param):
            # question_type -> type
            question_param['type'] = question_param.pop('question_type')

            question_form = QuestionForm(question_param)

            if not question_form.is_valid():
                errors = QuizAPIView.form_validation_errors(
                    errors=errors,
                    parent_key='{0}_question_{1}'.format(text_key, i),
                    form=question_form)

            question = {'form': question_form, 'answer_forms': []}

            for j, answer_param in enumerate(question_param['answers']):
                answer_form = AnswerForm(answer_param)

                if not answer_form.is_valid():
                    errors = QuizAPIView.form_validation_errors(
                        errors=errors,
                        parent_key='{0}_question_{1}_answer_{2}'.format(text_key, i, j),
                        form=answer_form)

                question['answer_forms'].append(answer_form)

            questions.append(question)

        return questions, errors

    @classmethod
    def validate_text_param(cls, text_param: dict, order: int, errors: dict, output_params: dict) -> (dict, dict):
        text_key = 'text_{0}'.format(order)
        text = {}

        # default difficulty
        if 'difficulty' not in text_param or not text_param['difficulty']:
            text_param['difficulty'] = 'intermediate_mid'

        try:
            text_param['difficulty'] = TextDifficulty.objects.get(slug=text_param['difficulty']).pk
        except ObjectDoesNotExist:
            errors['{0}_difficulty'.format(text_key)] = "text difficulty {0} does not exist".format(
                text_param['difficulty'])

        text['text_form'] = TextForm(text_param)

        if 'questions' not in text_param:
            raise ValidationError(message="'questions' field is required.")

        text['questions'], errors = QuizAPIView.validate_question_param(text_key, text_param['questions'], errors)

        if not text['text_form'].is_valid():
            errors = QuizAPIView.form_validation_errors(errors=errors, parent_key=text_key, form=text['text_form'])

        output_params[text_key] = text

        return output_params, errors

    def get(self, request, *args, **kwargs):
        if 'pk' in kwargs:
            try:
                # TODO(andrew): disallow empty quizzes
                # query reverse relation to consolidate queries
                # since Text.quiz can be null this may raise ObjectDoesNotExist when the quiz itself exists
                quiz_texts = Text.objects.select_related('quiz').filter(quiz=kwargs['pk'])

                if not quiz_texts:
                    raise ObjectDoesNotExist()

                quiz = quiz_texts[0].quiz

                return HttpResponse(json.dumps(quiz.to_dict(texts=quiz_texts)))
            except ObjectDoesNotExist:
                return HttpResponse(
                    json.dumps(
                        {'errors': {'quiz': "quiz with id {0} does not exist".format(kwargs['pk'])}}), status=400)

        quizzes = [quiz.to_dict() for quiz in self.model.objects.all()]

        return HttpResponse(json.dumps(quizzes))

    def post(self, request, *args, **kwargs):
        try:
            quiz_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(json.dumps({'errors': {'json': str(e)}}), status=400)

        try:
            # TODO (andrew): use json schema validation here (http://json-schema.org)
            if not isinstance(quiz_params, dict) or 'texts' not in quiz_params:
                raise ValidationError(message='bad payload.')

            text_params = quiz_params.pop('texts')
            text_params, errors = QuizAPIView.validate_text_params(text_params)
        except ValidationError as e:
            return HttpResponse(json.dumps({'errors': e.message}),
                                status=400)

        if errors:
            return HttpResponse(json.dumps({'errors': errors}), status=400)

        try:
            quiz = Quiz.create(text_params=text_params, **quiz_params)
            quiz.save()

            return HttpResponse(json.dumps({'id': quiz.pk}))
        except IntegrityError as e:
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))
