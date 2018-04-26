from django.urls import path
from instructor_admin.views import TextAdminView, AdminCreateQuizView


urlpatterns = [
    path('', TextAdminView.as_view(), name='admin'),
    path('create-quiz', AdminCreateQuizView.as_view(), name='admin-create-quiz')
]
