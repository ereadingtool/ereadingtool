from django.forms import ModelForm

from quiz.models import Quiz


class QuizForm(ModelForm):
    class Meta:
        model = Quiz
        fields = ('title', 'introduction', 'tags', )

