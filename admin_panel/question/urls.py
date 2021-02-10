from django.urls import path

from question.views import QuestionAPIView

urlpatterns = [
    path('', QuestionAPIView.as_view()),
    path('<int:pk>', QuestionAPIView.as_view()),
]
