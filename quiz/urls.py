from django.urls import path
from quiz.views import QuizView, QuizLoadElm, QuizAPIView, QuizTagAPIView

urlpatterns = [
    path('api/quiz/<int:pk>/', QuizAPIView.as_view(), name='quiz-api'),
    path('api/quiz/', QuizAPIView.as_view(), name='quiz-api'),
    path('api/quiz/<int:pk>/tag/', QuizTagAPIView.as_view(), name='quiz-tag-api'),

    path('quiz/<int:pk>/load_elm.js', QuizLoadElm.as_view(), name='quiz-load-elm'),
    path('quiz/<int:pk>/', QuizView.as_view(), name='quiz'),
]
