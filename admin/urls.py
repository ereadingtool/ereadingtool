from django.urls import path
from admin.views import AdminView


urlpatterns = [
    path('', AdminView.as_view(), name='admin')
]
