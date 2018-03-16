from django.urls import path
from text.views import TextDetailView


urlpatterns = [
    path('<slug:slug>/', TextDetailView.as_view(), name='text-detail'),
]
