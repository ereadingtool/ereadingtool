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


class ValidationException(Exception):
    def __init__(self, errors : dict):
        self.errors = errors


class FormValidationException(Exception):
    def __init__(self, form : ModelForm):
        self.form = form
        self.errors = self.form_validation_errors()

    def form_validation_errors(self):
        return {k: str(self.form.errors[k].data[0].message) for k in self.form.errors.keys()}


class JSONException(Exception):
    def __init__(self, json_str : str, json_decoder_exp: json.JSONDecodeError):
        self.json = json_str
        self.json_exp = json_decoder_exp


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

        try:
            with transaction.atomic():
                try:
                    text_params = json.loads(request.body.decode('utf8'))
                except json.JSONDecodeError as e:
                    raise JSONException(json_str=request.body.decode('utf8'), json_decoder_exp=e)

                # default difficulty
                if 'difficulty' not in text_params or not text_params['difficulty']:
                    text_params['difficulty'] = 'intermediate_mid'

                try:
                    text_params['difficulty'] = TextDifficulty.objects.get(slug=text_params['difficulty']).pk
                except ObjectDoesNotExist:
                    raise ValidationException(
                        errors={"errors": {'difficulty': "text difficulty {0} does not exist".format(
                            text_params['difficulty'])
                    }})

                text_form = TextForm(text_params)

                if not text_form.is_valid():
                    raise FormValidationException(form=text_form)

                text = text_form.save()

                for question_param in text_params['questions']:
                    question_param['text'] = text.pk

                    # ignore 'order' param for now
                    question_param.pop('order')
                    # question_type -> type
                    question_param['type'] = question_param.pop('question_type')

                    question_form = QuestionForm(question_param)

                    if not question_form.is_valid():
                        raise FormValidationException(form=question_form)

                    question = question_form.save()

                    for answer_param in question_param['answers']:
                        answer_param['question'] = question.pk
                        # ignore 'order' param for now
                        answer_param.pop('order')

                        answer_form = AnswerForm(answer_param)

                        if not answer_form.is_valid():
                            raise FormValidationException(form=answer_form)

                        answer_form.save()

        except (ValidationException, JSONException, FormValidationException) as exp:
            return HttpResponse(json.dumps({"errors": exp.errors}), status=400)

        return HttpResponse(json.dumps({"id": text.pk}))
