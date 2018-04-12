import json

from django.http import HttpResponse
from django.views.generic import TemplateView, View
from django.db.models import ObjectDoesNotExist
from text.models import Text, TextDifficulty
from django.db import transaction

from question.forms import QuestionForm, AnswerForm, ModelForm
from text.forms import TextForm


class AdminView(TemplateView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'admin.html'


class AdminCreateQuizView(TemplateView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'create_quiz.html'


class AdminAPIView(View):
    model = Text

    def get(self, request):
        if 'difficulties' in request.GET.keys():
            return HttpResponse(json.dumps({d.slug: d.name for d in TextDifficulty.objects.all()}))
        else:
            texts = [text.to_dict() for text in self.model.objects.all()]

            return HttpResponse(json.dumps(list(texts)))

    def post(self, request, *args, **kwargs):
        text = None
        errors = {}
        questions = []

        def form_validation_errors(form):
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
            # ignore 'order' param for now
            question_param.pop('order')
            # question_type -> type
            question_param['type'] = question_param.pop('question_type')

            question_form = QuestionForm(question_param)

            if not question_form.is_valid():
                errors['question_{0}'.format(i)] = form_validation_errors(question_form)

            question = {'form': question_form, 'answer_forms': []}

            for j, answer_param in enumerate(question_param['answers']):
                # ignore 'order' param for now
                answer_param.pop('order')

                answer_form = AnswerForm(answer_param)

                if not answer_form.is_valid():
                    errors['question_{0}_answer_{1}'.format(i, j)] = form_validation_errors(answer_form)

                question['answer_forms'].append(answer_form)

            questions.append(question)

        if errors:
            return HttpResponse(json.dumps(errors), status=400)
        else:
            text = text_form.save()

            for question in questions:
                question = question['form'].save(commit=False)

                question.text = text
                question.save()

                for answer_form in question['answer_forms']:
                    answer = answer_form.save(commit=False)

                    answer.question = question
                    answer.save()

            return HttpResponse(json.dumps({"id": text.pk}))
