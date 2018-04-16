from django.urls import path

from text.views import TextAPIView

urlpatterns = [
    path('', TextAPIView.as_view()),
    path('<int:pk>', TextAPIView.as_view()),
]
