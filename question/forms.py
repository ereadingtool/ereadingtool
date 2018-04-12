from django.forms import ModelForm

from question.models import Question, Answer


class QuestionForm(ModelForm):
    class Meta:
        model = Question
        fields = ('text', 'body', 'type',)
        exclude = ('text',)


class AnswerForm(ModelForm):
    class Meta:
        model = Answer
        fields = ('text', 'correct', 'feedback', )
        exclude = ('question',)
