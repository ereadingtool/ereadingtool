from django.urls import path
from instructor_admin.views import QuizAdminView, AdminCreateEditQuizView, AdminCreateEditElmLoadView

urlpatterns = [
    path('quizzes/', QuizAdminView.as_view(), name='admin'),

    # template loads "load_elm.js" from either /quiz/<int:pk>/ or /quiz/
    # e.g. /quiz/<int:pk>/load_elm.js or /quiz/load_elm.js
    # (see template create_edit_quiz.html)
    path('quiz/load_elm.js', AdminCreateEditElmLoadView.as_view(), name="quiz-create-load-elm"),
    path('quiz/', AdminCreateEditQuizView.as_view(), name='quiz-create'),

    path('quiz/<int:pk>/load_elm.js', AdminCreateEditElmLoadView.as_view(), name="quiz-edit-load-elm"),
    path('quiz/<int:pk>/', AdminCreateEditQuizView.as_view(), name='quiz-edit'),
]
