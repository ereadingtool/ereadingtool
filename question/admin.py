from django.contrib import admin
from question.models import Question, Answer


class AnswerInline(admin.TabularInline):
    model = Answer


class QuestionAdmin(admin.ModelAdmin):
    inlines = [AnswerInline, ]


admin.site.register(Question, QuestionAdmin)
