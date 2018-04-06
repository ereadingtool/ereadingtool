from django.forms import ModelForm

from question.models import Question, Answer


class QuestionForm(ModelForm):
    class Meta:
        model = Question
        fields = ('text', 'body', 'type',)


class AnswerForm(ModelForm):
    class Meta:
        model = Answer
        fields = ('question', 'text', 'correct', 'feedback', )
