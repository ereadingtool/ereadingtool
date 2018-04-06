import json

from django.http import HttpResponse
from django.views.generic import TemplateView, View
from text.models import Text, TextDifficulty

from question.forms import QuestionForm, AnswerForm
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
        texts = [text.to_dict() for text in self.model.objects.all()]

        return HttpResponse(json.dumps(list(texts)))

    def post(self, request, *args, **kwargs):
        def form_validation_errors(form):
            return {k: str(form.errors[k].data[0].message) for k in form.errors.keys()}

        text_params = json.loads(request.body.decode('utf8'))

        # default difficulty
        if 'difficulty' not in text_params or not text_params['difficulty']:
            text_params['difficulty'] = 'intermediate_mid'

        text_params['difficulty'] = TextDifficulty.objects.get(slug=text_params['difficulty']).pk

        text_form = TextForm(text_params)

        if not text_form.is_valid():
            return HttpResponse(json.dumps(form_validation_errors(text_form)))

        text = text_form.save()

        for question_param in text_params['questions']:
            question_param['text'] = text.pk

            # ignore 'order' param for now
            question_param.pop('order')
            # question_type -> type
            question_param['type'] = question_param.pop('question_type')

            question_form = QuestionForm(question_param)

            if not question_form.is_valid():
                return HttpResponse(json.dumps(form_validation_errors(question_form)))

            question = question_form.save()

            for answer_param in question_param['answers']:
                answer_param['question'] = question.pk
                # ignore 'order' param for now
                answer_param.pop('order')

                answer_form = AnswerForm(answer_param)

                if not answer_form.is_valid():
                    return HttpResponse(json.dumps(form_validation_errors(answer_form)))

                answer = answer_form.save()

        return HttpResponse(json.dumps(["text_id", text.pk]))
