import json

from django.db.models import ObjectDoesNotExist
from django.http import HttpResponse
from django.views.generic import View

from question.forms import QuestionForm, AnswerForm
from text.forms import TextForm, ModelForm
from text.models import Text, TextDifficulty
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy


class TextAPIView(LoginRequiredMixin, View):
    login_url = reverse_lazy('student-login')

    model = Text

    def get(self, request, *args, **kwargs):
        if 'difficulties' in request.GET.keys():
            return HttpResponse(json.dumps({d.slug: d.name for d in TextDifficulty.objects.all()}))

        if 'pk' in kwargs:
            try:
                text = Text.objects.get(pk=kwargs['pk'])

                return HttpResponse(json.dumps(text.to_dict()))
            except ObjectDoesNotExist:
                return HttpResponse(errors={"errors": {'text': "text with id {0} does not exist".format(
                    kwargs['pk'])
                }}, status=400)

        texts = [text.to_dict() for text in self.model.objects.all()]

        return HttpResponse(json.dumps(list(texts)))

    def post(self, request, *args, **kwargs):
        text = None
        errors = {}
        questions = []

        def form_validation_errors(form: ModelForm) -> dict:
            return {k: str(form.errors[k].data[0].message) for k in form.errors.keys()}

        try:
            text_params = json.loads(request.body.decode('utf8'))
        except json.JSONDecodeError as e:
            return HttpResponse(errors={"errors": {'json': str(e)}}, status=400)

        # default difficulty
        if 'difficulty' not in text_params or not text_params['difficulty']:
            text_params['difficulty'] = 'intermediate_mid'

        try:
            text_params['difficulty'] = TextDifficulty.objects.get(slug=text_params['difficulty']).pk
        except ObjectDoesNotExist:
            return HttpResponse(errors={"errors": {'difficulty': "text difficulty {0} does not exist".format(
                    text_params['difficulty'])
                }}, status=400)

        text_form = TextForm(text_params)

        if not text_form.is_valid():
            errors['text'] = form_validation_errors(text_form)

        for i, question_param in enumerate(text_params['questions']):
            # question_type -> type
            question_param['type'] = question_param.pop('question_type')

            question_form = QuestionForm(question_param)

            if not question_form.is_valid():
                errors['question_{0}'.format(i)] = form_validation_errors(question_form)

            question = {'form': question_form, 'answer_forms': []}

            for j, answer_param in enumerate(question_param['answers']):
                answer_form = AnswerForm(answer_param)

                if not answer_form.is_valid():
                    errors['question_{0}_answer_{1}'.format(i, j)] = form_validation_errors(answer_form)

                question['answer_forms'].append(answer_form)

            questions.append(question)

        if errors:
            # flatten error dictionary, e.g.:
            # { "question_0_answer_0": {"feedback": "This field is required."} } ->
            # { "question_0_answer_0_feedback": "This field is required." }
            return HttpResponse(json.dumps({
                '_'.join([k, k1]): v[k1] for (k, v) in errors.items() for k1 in v.keys()
            }), status=400)
        else:
            text = text_form.save()

            for i, question in enumerate(questions):
                question_obj = question['form'].save(commit=False)

                question_obj.text = text

                question_obj.order = i
                question_obj.save()

                for j, answer_form in enumerate(question['answer_forms']):
                    answer = answer_form.save(commit=False)

                    answer.question = question_obj
                    answer.order = j
                    answer.save()

            return HttpResponse(json.dumps({"id": text.pk}))
