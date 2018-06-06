import json
from typing import TypeVar, Optional, List

from django.contrib.auth.mixins import LoginRequiredMixin
from django.core.exceptions import ValidationError, ObjectDoesNotExist
from django.db import IntegrityError
from django.http import Http404, HttpResponseNotAllowed
from django.http import HttpResponse, HttpRequest
from django.urls import reverse
from django.urls import reverse_lazy
from django.views.generic import TemplateView
from django.views.generic import View

from mixins.model import WriteLocked
from mixins.view import ElmLoadJsView
from question.forms import QuestionForm, AnswerForm
from question.models import Question
from quiz.forms import QuizForm
from quiz.models import Quiz
from text.forms import TextForm, ModelForm
from text.models import TextDifficulty, Text
from user.views.mixin import ProfileView


class QuizView(ProfileView, TemplateView):
    login_url = reverse_lazy('student-login')
    template_name = 'quiz.html'

    model = Quiz

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('quiz does not exist')

        return super(QuizView, self).get(request, *args, **kwargs)


class QuizLoadElm(ElmLoadJsView):
    def get_context_data(self, **kwargs) -> dict:
        context = super(QuizLoadElm, self).get_context_data(**kwargs)

        context['elm']['quiz_id'] = {'quote': False, 'safe': True, 'value': context['pk']}

        return context


class QuizTagAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')

    model = Quiz

    allowed_methods = ['get', 'put', 'delete']

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            tag = json.loads(request.body.decode('utf8'))
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                quiz.tags.remove(tag)

                return HttpResponse(json.dumps(True))
            except IntegrityError:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        except Quiz.DoesNotExist:
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponse(json.dumps({'errors': 'tag not valid'}))

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        if not len(request.body.decode('utf8')):
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            tag = json.loads(request.body.decode('utf8'))
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                if isinstance(tag, list):
                    quiz.tags.add(*tag)
                else:
                    quiz.tags.add(tag)

                return HttpResponse(json.dumps(tag))
            except IntegrityError:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        except Quiz.DoesNotExist:
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponse(json.dumps({'errors': 'tag not valid'}))

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                tags = [tag.name for tag in quiz.tags.all()]

                return HttpResponse(json.dumps(tags))
            except IntegrityError:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        except Quiz.DoesNotExist:
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))
        except UnicodeDecodeError:
            return HttpResponse(json.dumps({'errors': 'tag not valid'}))


class QuizAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')

    model = Quiz

    allowed_methods = ['get', 'put', 'post', 'delete']

    @classmethod
    def form_validation_errors(cls, errors: dict, parent_key: str, form: ModelForm) -> dict:
        for k in form.errors.keys():
            errors['_'.join([parent_key, k])] = str(form.errors[k].data[0].message)

        return errors

    @classmethod
    def validate_text_params(cls, text_params: TypeVar('list(dict)'), errors: dict,
                             texts: Optional[List[TypeVar('Text')]]=None) -> (dict, dict):
        new_text_params = {}

        for i, text_param in enumerate(text_params):
            new_text_params, errors = QuizAPIView.validate_text_param(
               text_param=text_param,
               order=i,
               errors=errors,
               text_instance=texts[i] if texts else None,
               output_params=new_text_params)

        return new_text_params, errors

    @classmethod
    def validate_quiz_params(cls, quiz_params: dict, errors: dict,
                             quiz: Optional[TypeVar('Quiz')]=None) -> (dict, dict):
        quiz_form = QuizForm(instance=quiz, data=quiz_params)

        if not quiz_form.is_valid():
            errors = QuizAPIView.form_validation_errors(
                    errors=errors,
                    parent_key='quiz',
                    form=quiz_form)

        quiz_params = {'quiz': quiz, 'form': quiz_form}

        return quiz_params, errors

    @classmethod
    def validate_question_param(cls, text_key: str, question_param: dict, errors: dict,
                                question_instances: List[TypeVar('Question')]=None) -> (list, dict):
        questions = []

        for i, question_param in enumerate(question_param):
            question_instance = None
            answer_instances = []

            # question_type -> type
            question_param['type'] = question_param.pop('question_type')

            if question_instances:
                question_instance = question_instances[i]
                answer_instances = question_instance.answers.all()

            question_form = QuestionForm(instance=question_instance, data=question_param)

            if not question_form.is_valid():
                errors = QuizAPIView.form_validation_errors(
                    errors=errors,
                    parent_key='{0}_question_{1}'.format(text_key, i),
                    form=question_form)

            question = {'form': question_form, 'answer_forms': []}

            for j, answer_param in enumerate(question_param['answers']):
                answer_instance = None

                if answer_instances:
                    answer_instance = answer_instances[j]

                answer_form = AnswerForm(instance=answer_instance, data=answer_param)

                if not answer_form.is_valid():
                    errors = QuizAPIView.form_validation_errors(
                        errors=errors,
                        parent_key='{0}_question_{1}_answer_{2}'.format(text_key, i, j),
                        form=answer_form)

                question['answer_forms'].append(answer_form)

            questions.append(question)

        return questions, errors

    @classmethod
    def validate_text_param(cls, text_param: dict, order: int, errors: dict, output_params: dict,
                            text_instance: Optional[TypeVar('Text')]=None) -> (dict, dict):
        text_key = 'text_{0}'.format(order)
        text = {}

        # default difficulty
        if 'difficulty' not in text_param or not text_param['difficulty']:
            text_param['difficulty'] = 'intermediate_mid'

        try:
            text_param['difficulty'] = TextDifficulty.objects.get(slug=text_param['difficulty']).pk
        except TextDifficulty.DoesNotExist:
            errors['{0}_difficulty'.format(text_key)] = "text difficulty {0} does not exist".format(
                text_param['difficulty'])

        text['text_form'] = TextForm(instance=text_instance, data=text_param)

        if 'questions' not in text_param:
            raise ValidationError(message="'questions' field is required.")

        text['questions'], errors = QuizAPIView.validate_question_param(text_key,
                                                                        text_param['questions'], errors,
                                                                        question_instances=
                                                                        text_instance.questions.all() if text_instance
                                                                        else None)

        if not text['text_form'].is_valid():
            errors = QuizAPIView.form_validation_errors(errors=errors, parent_key=text_key, form=text['text_form'])

        output_params[text_key] = text

        return output_params, errors

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)
        try:
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            try:
                quiz.delete()

                return HttpResponse(json.dumps({'id': quiz.pk, 'deleted': True}))
            except WriteLocked:
                return HttpResponse(json.dumps({'errors': 'quiz {0} is locked.'.format(kwargs['pk'])}))

        except Quiz.DoesNotExist:
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            quiz = Quiz.objects.get(pk=kwargs['pk'])

            profile = self.request.user.instructor

            quiz_params, text_params, resp = self.validate_params(request.body.decode('utf8'), quiz)

            if resp:
                return resp

            try:
                quiz = Quiz.update(quiz_params=quiz_params, text_params=text_params)
                quiz.last_modified_by = profile

                quiz.save()

                return HttpResponse(json.dumps({'id': quiz.pk, 'updated': True}))
            except WriteLocked:
                return HttpResponse(json.dumps({'errors': 'quiz {0} is locked.'.format(kwargs['pk'])}))
            except IntegrityError:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        except (Quiz.DoesNotExist, ObjectDoesNotExist):
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' in kwargs:
            try:
                # query reverse relation to consolidate queries
                quiz_texts = Text.objects.select_related('quiz').filter(quiz=kwargs['pk'])

                if not quiz_texts.exists():
                    raise Quiz.DoesNotExist()

                quiz = quiz_texts[0].quiz

                return HttpResponse(json.dumps(quiz.to_dict(texts=quiz_texts)))
            except Text.DoesNotExist:
                return HttpResponse(
                    json.dumps(
                        {'errors': {'quiz': "quiz with id {0} does not exist".format(kwargs['pk'])}}), status=400)

        quizzes = [quiz.to_summary_dict() for quiz in self.model.objects.all()]

        return HttpResponse(json.dumps(quizzes))

    def validate_params(self, quiz_params: str, quiz: Optional[TypeVar('Quiz')]=None) -> (dict, dict, HttpResponse):
        errors = resp = text_params = None

        try:
            quiz_params = json.loads(quiz_params)
        except json.JSONDecodeError as e:
            resp = HttpResponse(json.dumps({'errors': {'json': str(e)}}), status=400)

        try:
            # TODO (andrew): use json schema validation (http://json-schema.org)
            if not isinstance(quiz_params, dict) or 'texts' not in quiz_params:
                raise ValidationError(message='bad payload.')

            text_params = quiz_params.pop('texts')

            quiz_params, errors = QuizAPIView.validate_quiz_params(quiz_params, {}, quiz)
            text_params, errors = QuizAPIView.validate_text_params(text_params, errors,
                                                                   texts=quiz.texts.all() if quiz else None)

        except ValidationError as e:
            resp = HttpResponse(json.dumps({'errors': e.message}), status=400)

        if errors:
            resp = HttpResponse(json.dumps({'errors': errors}), status=400)

        return quiz_params, text_params, resp

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        quiz_params, text_params, resp = self.validate_params(request.body.decode('utf8'))

        if resp:
            return resp

        try:
            profile = self.request.user.instructor

            quiz = Quiz.create(text_params=text_params, quiz_params=quiz_params)

            quiz.created_by = profile
            quiz.save()

            return HttpResponse(json.dumps({'id': quiz.pk, 'redirect': reverse('quiz-edit', kwargs={'pk': quiz.pk})}))
        except (IntegrityError, ObjectDoesNotExist):
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))
