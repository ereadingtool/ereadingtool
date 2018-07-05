from django.urls import path
from instructor_admin.views import TextAdminView, AdminCreateEditTextView, AdminCreateEditElmLoadView

urlpatterns = [
    path('quizzes/', TextAdminView.as_view(), name='admin'),

    # template loads "load_elm.js" from either /quiz/<int:pk>/ or /quiz/
    # e.g. /quiz/<int:pk>/load_elm.js or /quiz/load_elm.js
    # (see template create_edit_quiz.html)
    path('quiz/load_elm.js', AdminCreateEditElmLoadView.as_view(), name="quiz-create-load-elm"),
    path('quiz/', AdminCreateEditTextView.as_view(), name='quiz-create'),

    path('quiz/<int:pk>/load_elm.js', AdminCreateEditElmLoadView.as_view(), name="quiz-edit-load-elm"),
    path('quiz/<int:pk>/', AdminCreateEditTextView.as_view(), name='quiz-edit'),
]
