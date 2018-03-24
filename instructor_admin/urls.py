from django.urls import path
from instructor_admin.views import AdminView, AdminCreateQuizView


urlpatterns = [
    path('', AdminView.as_view(), name='admin'),
    path('create-quiz', AdminCreateQuizView.as_view(), name='admin-create-quiz')
]
