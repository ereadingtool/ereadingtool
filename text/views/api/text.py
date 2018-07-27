import json
import jsonschema
from typing import TypeVar, Optional, List, Dict, AnyStr

from django.contrib.auth.mixins import LoginRequiredMixin
from django.core.exceptions import ValidationError, ObjectDoesNotExist
from django.db import IntegrityError
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse
from django.urls import reverse_lazy
from django.views.generic import View

from mixins.model import WriteLocked
from question.forms import QuestionForm, AnswerForm
from question.models import Question

from text.forms import TextForm, TextSectionForm, ModelForm
from text.models import TextDifficulty, Text, TextSection


class TextAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['get', 'put', 'post', 'delete']

    model = Text

    difficulties = {difficulty: 1 for difficulty in TextDifficulty.difficulty_keys()}
    tags = {tag.name: 1 for tag in Text.tag_choices()}

    @classmethod
    def form_validation_errors(cls, errors: Dict, parent_key: AnyStr, form: ModelForm) -> Dict:
        for k in form.errors.keys():
            errors['_'.join([parent_key, k])] = '. '.join([err for err in form.errors[k]])

        return errors

    @classmethod
    def validate_text_section_params(cls, text_section_params: List[Dict], errors: Dict,
                                     text_sections: Optional[List[TypeVar('TextSection')]]=None) -> (Dict, Dict):
        new_text_params = {}

        for i, text_section_param in enumerate(text_section_params):
            new_text_params, errors = TextAPIView.validate_text_section_param(
               text_section_param=text_section_param,
               order=i,
               errors=errors,
               text_section_instance=text_sections[i] if text_sections else None,
               output_params=new_text_params)

        return new_text_params, errors

    @classmethod
    def validate_text_params(cls, text_params: Dict, errors: Dict,
                             text: Optional[TypeVar('Text')]=None) -> (Dict, Dict):
        # default difficulty
        if 'difficulty' not in text_params or not text_params['difficulty']:
            text_params['difficulty'] = 'intermediate_mid'

        try:
            text_params['difficulty'] = TextDifficulty.objects.get(slug=text_params['difficulty']).pk
        except TextDifficulty.DoesNotExist:
            errors['text_difficulty'] = f"text difficulty {text_params['difficulty']} does not exist"

        text_form = TextForm(instance=text, data=text_params)

        if not text_form.is_valid():
            errors = cls.form_validation_errors(
                    errors=errors,
                    parent_key='text',
                    form=text_form)

        text_params = {'text': text, 'form': text_form}

        return text_params, errors

    @classmethod
    def validate_question_param(cls, text_key: AnyStr, question_param: Dict, errors: Dict,
                                question_instances: List[TypeVar('Question')]=None) -> (List, Dict):
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
                errors = TextAPIView.form_validation_errors(
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
                    errors = TextAPIView.form_validation_errors(
                        errors=errors,
                        parent_key='{0}_question_{1}_answer_{2}'.format(text_key, i, j),
                        form=answer_form)

                question['answer_forms'].append(answer_form)

            questions.append(question)

        return questions, errors

    @classmethod
    def validate_text_section_param(cls, text_section_param: dict, order: int, errors: dict, output_params: dict,
                                    text_section_instance: Optional[TypeVar('TextSection')]=None) -> (dict, dict):
        text_section = dict()
        text_section_key = f'textsection_{order}'

        text_section_param['order'] = order

        text_section['text_section_form'] = TextSectionForm(instance=text_section_instance, data=text_section_param)

        if 'questions' not in text_section_param:
            raise ValidationError(message="'questions' field is required.")

        text_section['questions'], errors = TextAPIView.validate_question_param(
            text_section_key,
            text_section_param['questions'],
            errors,
            question_instances=text_section_instance.questions.all() if text_section_instance else None)

        if not text_section['text_section_form'].is_valid():
            errors = TextAPIView.form_validation_errors(errors=errors, parent_key=text_section_key,
                                                        form=text_section['text_section_form'])

        output_params[text_section_key] = text_section

        return output_params, errors

    def delete(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)
        try:
            text = Text.objects.get(pk=kwargs['pk'])

            try:
                text.delete()

                return HttpResponse(json.dumps({
                    'id': kwargs['pk'],
                    'deleted': True,
                    'redirect': str(reverse_lazy('admin'))}))
            except WriteLocked:
                return HttpResponseServerError(json.dumps({'errors': 'text {0} is locked.'.format(kwargs['pk'])}))

        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    def put(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            text = Text.objects.get(pk=kwargs['pk'])

            profile = self.request.user.instructor

            text_params, text_sections_params, resp = self.validate_params(request.body.decode('utf8'), text)

            if resp:
                return resp

            try:
                text = Text.update(text_params=text_params, text_sections_params=text_sections_params)
                text.last_modified_by = profile

                text.save()

                return HttpResponse(json.dumps({'id': text.pk, 'updated': True}))
            except WriteLocked:
                return HttpResponseServerError(json.dumps({'errors': 'text {0} is locked.'.format(kwargs['pk'])}))
            except IntegrityError:
                return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

        except (Text.DoesNotExist, ObjectDoesNotExist):
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        filter_by = {}

        difficulties = request.GET.getlist('difficulty')
        tags = request.GET.getlist('tag')

        valid_difficulties = all(list(map(lambda difficulty: difficulty in self.difficulties, difficulties)))
        valid_tags = all(list(map(lambda tag: tag in self.tags, tags)))

        if not (valid_difficulties or valid_tags):
            return HttpResponseServerError(
                json.dumps(
                    {'errors': {'text': "something went wrong"}}), status=400)

        if 'difficulties' in request.GET.keys():
            return HttpResponse(json.dumps({d.slug: d.name for d in TextDifficulty.objects.all()}))

        if 'pk' in kwargs:
            try:
                # query reverse relation to consolidate queries
                text_sections = TextSection.objects.select_related('text').filter(text=kwargs['pk'])

                if not text_sections.exists():
                    raise Text.DoesNotExist()

                text = text_sections[0].text

                return HttpResponse(json.dumps(text.to_dict(text_sections=text_sections)))
            except Text.DoesNotExist:
                return HttpResponseServerError(
                    json.dumps(
                        {'errors': {'text': "text with id {0} does not exist".format(kwargs['pk'])}}), status=400)

        if 'difficulty' in request.GET.keys():
            filter_by['difficulty__slug__in'] = difficulties

        if 'tag' in request.GET.keys():
            filter_by['tags__name_in'] = tags

        texts = [text.to_summary_dict() for text in self.model.objects.filter(**filter_by)]

        return HttpResponse(json.dumps(texts))

    def validate_params(self, text_params: AnyStr, text: Optional[TypeVar('Text')]=None) -> (Dict, Dict, HttpResponse):
        errors = resp = text_sections_params = None

        try:
            text_params = json.loads(text_params)
        except json.JSONDecodeError as e:
            resp = HttpResponse(json.dumps({'errors': {'json': str(e)}}), status=400)

        try:
            jsonschema.validate(text_params, Text.to_json_schema())

            text_sections_params = text_params.pop('text_sections')

            text_params, errors = TextAPIView.validate_text_params(text_params, {}, text)
            text_sections_params, errors = TextAPIView.validate_text_section_params(text_sections_params,
                                                                                    errors,
                                                                                    text_sections=text.sections.all()
                                                                                    if text else None)
        except jsonschema.ValidationError as e:
            resp = HttpResponse(json.dumps({
                'errors': {
                    'malformed_json': e.message + (
                        ' at ' + '_'.join([str(path) for path in e.relative_path])
                        if e.relative_path else '')
                }
            }), status=400)
        except ValidationError as e:
            resp = HttpResponse(json.dumps({'errors': e.message}), status=400)

        if errors:
            resp = HttpResponse(json.dumps({'errors': errors}), status=400)

        return text_params, text_sections_params, resp

    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text_params, text_sections_params, resp = self.validate_params(request.body.decode('utf8'))

        if resp:
            return resp

        try:
            profile = self.request.user.instructor

            text = Text.create(text_params=text_params, text_sections_params=text_sections_params)

            text.created_by = profile
            text.save()

            return HttpResponse(json.dumps({'id': text.pk, 'redirect': reverse('text-edit', kwargs={'pk': text.pk})}))
        except (IntegrityError, ObjectDoesNotExist) as e:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))
