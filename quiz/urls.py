from django.urls import path
from quiz.views.template import QuizLoadElm, QuizView

from quiz.views.api.quiz import QuizAPIView
from quiz.views.api.tag import QuizTagAPIView
from quiz.views.api.lock import QuizLockAPIView

urlpatterns = [
    path('api/quiz/<int:pk>/', QuizAPIView.as_view(), name='quiz-api'),
    path('api/quiz/', QuizAPIView.as_view(), name='quiz-api'),

    path('api/quiz/<int:pk>/tag/', QuizTagAPIView.as_view(), name='quiz-tag-api'),
    path('api/quiz/<int:pk>/lock/', QuizLockAPIView.as_view(), name='quiz-lock-api'),

    path('quiz/<int:pk>/load_elm.js', QuizLoadElm.as_view(), name='quiz-load-elm'),
    path('quiz/<int:pk>/', QuizView.as_view(), name='quiz'),
]
