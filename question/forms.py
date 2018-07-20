from django.forms import ModelForm

from question.models import Question, Answer


class QuestionForm(ModelForm):
    class Meta:
        model = Question
        fields = ('body', 'type',)
        exclude = ('text_section',)

    def clean(self):
        if len(list(filter(lambda ans: ans['correct'], self.data['answers']))) > 1 or \
                not any(map(lambda ans: ans['correct'], self.data['answers'])):
            self.errors.setdefault('answers', [])
            self.errors['answers'].append('You must choose a correct answer for this question.')

        super(QuestionForm, self).clean()


class AnswerForm(ModelForm):
    class Meta:
        model = Answer
        fields = ('text', 'correct', 'feedback', )
        exclude = ('question',)
