import json
import gzip
from logging import BASIC_FORMAT
from report.models import StudentReadingsComplete, StudentReadingsInProgress
import jsonschema
from typing import TypeVar, Optional, List, Dict, AnyStr, Union, Set

from django.core.exceptions import ValidationError, ObjectDoesNotExist
from django.db import IntegrityError, models
from django.http import HttpResponse, HttpRequest, HttpResponseServerError
from django.http import HttpResponseNotAllowed
from django.urls import reverse
from django.urls import reverse_lazy
from ereadingtool.views import APIView

from mixins.model import WriteLocked
from question.forms import QuestionForm, AnswerForm
from question.models import Question

from text.forms import TextForm, TextSectionForm, ModelForm
from text.models import TextDifficulty, Text, TextRating, TextSection, text_statuses

from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from auth.normal_auth import jwt_valid


Student = TypeVar('Student')
Instructor = TypeVar('Instructor')


def or_filters(filters):
    status_filter = None

    for f in filters:
        if status_filter:
            status_filter |= f
        else:
            status_filter = f

    return status_filter

@method_decorator(csrf_exempt, name='dispatch')
class TextAPIView(APIView):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['get', 'put', 'post', 'delete']

    model = Text

    @classmethod
    def form_validation_errors(cls, errors: Dict, parent_key: AnyStr, form: ModelForm) -> Dict:
        for k in form.errors.keys():
            errors['_'.join([parent_key, k])] = '. '.join([err for err in form.errors[k]])

        return errors

    @classmethod
    def validate_text_section_params(cls, text_section_params: List[Dict], errors: Dict,
                                     text_sections: Optional[List['TextSection']] = None) -> (Dict, Dict):
        new_text_params = {}

        for i, text_section_param in enumerate(text_section_params):
            try:
                text_section_instance = text_sections[i]
            except (IndexError, TypeError):
                text_section_instance = None

            new_text_params, errors = TextAPIView.validate_text_section_param(
               text_section_param=text_section_param,
               order=i,
               errors=errors,
               text_section_instance=text_section_instance,
               output_params=new_text_params)

        return new_text_params, errors

    @classmethod
    def validate_text_params(cls, text_params: Dict, errors: Dict,
                             text: Optional['Text'] = None) -> (Dict, Dict):
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
                                question_instances: List['Question'] = None) -> (List, Dict):
        questions = []

        for i, question_param in enumerate(question_param):
            question_instance = None
            answer_instances = []

            # question_type -> type
            question_param['type'] = question_param.pop('question_type')

            try:
                if question_instances:
                    question_instance = question_instances[i]
                    answer_instances = question_instance.answers.all()
            except:
                # silently fail on questions not in the query
                pass

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
    def validate_text_section_param(cls, text_section_param: Dict, order: int, errors: Dict, output_params: Dict,
                                    text_section_instance: Optional['TextSection'] = None) -> (Dict, Dict):
        text_section = dict()
        text_section_key = f'textsection_{order}'

        text_section_param['order'] = order

        text_section['text_section_form'] = TextSectionForm(instance=text_section_instance, data=text_section_param)

        if 'questions' not in text_section_param:
            raise ValidationError(message="'questions' field is required.")

        # `text_params` comes off the HttpRequest and is more up to date than the database. It still needs to be verified,
        # but a bug existed in `validate_question_param(..)` where we went out of bounds checking the `QueryString` for an
        # item that had yet to be added. So we check to see if the list on the request is shorter than the `QueryString`
        # returned from the database. The questions are verified once added to the database. Chicken before egg problem,
        # can't run `is_valid(..)` since `QuestionForm` contains the `Question` and this wasn't worth making an `_init_(..)`
        # for `Question`s on its own.
        if text_section_instance:
            existing_questions = text_section_instance.questions.all()
            l = len(existing_questions)
            r = len(text_section_param['questions'])
            for i in range(l,r):
                try:
                    new_question = text_section_param['questions'][i]
                    # validate the questions, note that we don't confirm `order` is correct or check that 
                    # `main_idea` is one of two valid options. However this will be checked once actually added
                    if 'answers' not in new_question or \
                       'body' not in new_question or \
                       'order' not in new_question or \
                       'question_type' not in new_question:
                        raise ValidationError
                except:
                    raise ValidationError(message="error parsing the new question")
        else:
            existing_questions = None

        text_section['questions'], errors = TextAPIView.validate_question_param(
            text_section_key,
            text_section_param['questions'],
            errors,
            question_instances=existing_questions)

        if not text_section['text_section_form'].is_valid():
            errors = TextAPIView.form_validation_errors(errors=errors, parent_key=text_section_key,
                                                        form=text_section['text_section_form'])

        text_section['instance'] = text_section_instance

        output_params[text_section_key] = text_section

        return output_params, errors

    @jwt_valid()
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
                    'redirect': str(reverse_lazy('admin-text-search'))}))
            except WriteLocked:
                return HttpResponseServerError(json.dumps({'errors': 'text {0} is locked.'.format(kwargs['pk'])}))

        except Text.DoesNotExist:
            return HttpResponseServerError(json.dumps({'errors': 'something went wrong'}))

    @jwt_valid()
    def patch(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if 'pk' not in kwargs:
            return HttpResponseNotAllowed(permitted_methods=self.allowed_methods)

        try:
            student = request.user.student.id
            try:
                text = Text.objects.get(pk=kwargs['pk'])
                vote_str = json.loads(request.body)['vote']
            except BaseException as be:
                return HttpResponse(json.dumps({'errors': 'something went wrong'}))

            # are they allowed to vote?
            l1 = StudentReadingsComplete.get_texts({'student_id': student})
            l2 = StudentReadingsInProgress.get_texts({'student_id': student})
            l3 = set(l1 + l2)

            if text not in l3:
                raise Exception

            if vote_str == "up":
                vote = 1
            elif vote_str == "down":
                vote = -1
            else:
                raise ValueError

            # Have they voted on this text before?
            try:
                # the student's vote if it was previously cast
                student_vote = TextRating.objects \
                                           .filter(text=text, student=student) \
                                           .get()
                prev_vote = student_vote.vote
            except BaseException as be:
                TextRating.objects.create(vote=vote, student_id=student, text_id=text.id)
                prev_vote = 0

            # They're changing a previously cast vote
            if prev_vote == 0:
                if vote == 1:
                    prev_vote = 1
                    text.rating = text.rating + 1
                elif vote == -1:
                    prev_vote = -1
                    text.rating = text.rating - 1
                else:
                    raise ValueError
            elif prev_vote == -1:
                if vote == 1:
                    prev_vote = 1
                    text.rating = text.rating + 2
                elif vote == -1:
                    prev_vote = 0
                    text.rating = text.rating + 1
                else:
                    raise ValueError
            elif prev_vote == 1:
                if vote == -1:
                    prev_vote = -1
                    text.rating = text.rating - 2
                elif vote == 1:
                    prev_vote = 0
                    text.rating = text.rating - 1
                else:
                    raise ValueError

            # update their vote history
            student_vote = TextRating.objects \
                                           .filter(text=text, student=student) \
                                           .get()
            student_vote.vote = prev_vote
            student_vote.save()
            text.save()

        except BaseException as be:
            return HttpResponse(json.dumps({'errors': 'something went wrong'}))

        return HttpResponse(json.dumps({'textId': text.pk, 'vote': vote_str, 'rating': text.rating}))


    @jwt_valid()
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

    @jwt_valid()
    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        text = None
        text_sections = None
        filter_by = {}

        user = request.user.student if hasattr(request.user, 'student') else request.user.instructor

        all_difficulties = {difficulty: 1 for difficulty in TextDifficulty.difficulty_keys()}
        all_tags = {tag.name: 1 for tag in Text.tag_choices()}
        all_statuses = dict(text_statuses)

        difficulties = request.GET.getlist('difficulty')
        tags = request.GET.getlist('tag')
        statuses = request.GET.getlist('status')

        if 'difficulties' in request.GET.keys():
            return HttpResponse(json.dumps([(d.slug, d.name) for d in TextDifficulty.objects.all()]))

        valid_difficulties = all(list(map(lambda difficulty: difficulty in all_difficulties, difficulties)))
        valid_tags = all(list(map(lambda tag: tag in all_tags, tags)))
        valid_statuses = all(list(map(lambda status: status in all_statuses, statuses)))

        if not (valid_difficulties or valid_tags or valid_statuses):
            return HttpResponseServerError(
                json.dumps(
                    {'errors': {'text': "something went wrong"}}), status=400)

        if 'pk' in kwargs:
            try:
                # query reverse relation to consolidate queries
                text_sections = TextSection.objects.select_related('text').filter(text=kwargs['pk'])

                if not text_sections.exists():
                    raise Text.DoesNotExist()

                text = text_sections[0].text
            except Text.DoesNotExist:
                return HttpResponseServerError(
                    json.dumps(
                        {'errors': {'text': "text with id {0} does not exist".format(kwargs['pk'])}}), status=400)

        if 'text_words' in request.GET.keys() and text is not None:
            return HttpResponse(json.dumps(text.text_words))

        if difficulties:
            filter_by['difficulty__slug__in'] = difficulties

        if tags:
            filter_by['tags__name__in'] = tags

        if 'pk' in kwargs:
            return HttpResponse(json.dumps(text.to_dict(text_sections=text_sections)))
        else:
            texts = [user.to_text_summary_dict(text=txt) for txt in
                     self.get_texts_queryset(user, set(statuses), filter_by)]

            zipped_json = gzip.compress(bytes(json.dumps(texts), 'utf-8'))
            response = HttpResponse(zipped_json) 
            response['Content-Encoding'] = 'gzip'
            response['Content-Length'] = len(zipped_json)

            return response

    def get_texts_queryset(self, user: Union[Student, Instructor], statuses: Set, filter_by: Dict):
        all_statuses = dict(text_statuses)
        subterfuge = {'tags__name__in': ['Hidden']}
        if 'instructor' in user.login_url:
            text_queryset = user.text_search_queryset.filter(**filter_by)
        else:
            text_queryset = user.text_search_queryset.filter(**filter_by).exclude(**subterfuge)

        # https://stackoverflow.com/questions/16475384/rename-a-dictionary-key
        view_filter_by = {'text_difficulty_slug' if k == 'difficulty__slug__in' else k:v for k,v in filter_by.items()}

        if view_filter_by:
            view_filter_by['text_difficulty_slug'] = view_filter_by['text_difficulty_slug'][0]

        view_filter_by['student_id'] = user.id

        if statuses == {'unread'}:
            # (all texts) - (complete U in_progress)
            all_texts_in_diff = set(Text.objects.filter(**filter_by).all())

            l1 = StudentReadingsComplete.get_texts(view_filter_by)
            l2 = StudentReadingsInProgress.get_texts(view_filter_by)

            # set difference
            soln_without_tags = all_texts_in_diff - set(l1 + l2)

            return soln_without_tags.intersection(text_queryset)

        elif 'read' in statuses:
            # trim down the filter by here so that it works for just difficulty, then do the intersection of the sets later
            without_tags = StudentReadingsComplete.get_texts(view_filter_by)
            all_texts_in_diff = set(Text.objects.filter(**filter_by).all())

            return all_texts_in_diff.intersection(without_tags)

        # Note that texts can be completed but still shown as in_progress
        elif 'in_progress' in statuses:
            without_tags = StudentReadingsInProgress.get_texts(view_filter_by)
            all_texts_in_diff = set(Text.objects.filter(**filter_by).all())

            return all_texts_in_diff.intersection(without_tags)
        else:
            return Text.objects.filter(**filter_by)


    def validate_params(self, text_params: AnyStr, text: Optional['Text'] = None) -> (Dict, Dict, HttpResponse):
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

    @jwt_valid()
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
