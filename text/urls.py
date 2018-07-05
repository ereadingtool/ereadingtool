from django.urls import path
from text.views.template import QuizLoadElm, QuizView

from text.views.api.quiz import QuizAPIView
from text.views.api.tag import QuizTagAPIView
from text.views.api.lock import TextLockAPIView

urlpatterns = [
    path('api/quiz/<int:pk>/', QuizAPIView.as_view(), name='quiz-api'),
    path('api/quiz/', QuizAPIView.as_view(), name='quiz-api'),

    path('api/quiz/<int:pk>/tag/', QuizTagAPIView.as_view(), name='quiz-tag-api'),
    path('api/quiz/<int:pk>/lock/', TextLockAPIView.as_view(), name='quiz-lock-api'),

    path('quiz/<int:pk>/load_elm.js', QuizLoadElm.as_view(), name='quiz-load-elm'),
    path('quiz/<int:pk>/', QuizView.as_view(), name='quiz'),
]
