from django.urls import path
from instructor_admin.views import TextAdminView, AdminCreateEditQuizView, AdminCreateEditElmLoadView


urlpatterns = [
    path('', TextAdminView.as_view(), name='admin'),
    path('create-quiz/load_elm.js', AdminCreateEditElmLoadView.as_view(), name='admin-create-quiz-elm-load'),
    path('create-quiz', AdminCreateEditQuizView.as_view(), name='admin-create-quiz')
]
