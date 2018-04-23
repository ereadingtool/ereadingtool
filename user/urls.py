from django.urls import path
from user.views import InstructorSignupAPIView, InstructorLoginAPIView, InstructorSignUpView, InstructorLoginView


api_urlpatterns = [
    path('api/instructor/signup/', InstructorSignupAPIView.as_view(), name='api-instructor-signup'),
    path('api/instructor/login/', InstructorLoginAPIView.as_view(), name='api-instructor-login'),
]

urlpatterns = [
    path('signup/instructor/', InstructorSignUpView.as_view(), name='instructor-signup'),
    path('login/instructor/', InstructorLoginView.as_view(), name='instructor-login')
] + api_urlpatterns
