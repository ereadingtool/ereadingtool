from django.urls import path
from instructor_admin.views import AdminView


urlpatterns = [
    path('', AdminView.as_view(), name='admin')
]
