from django.urls import path
from user.views import InstructorSignupAPIView, InstructorLoginAPIView, InstructorSignUpView, InstructorLoginView


api_urlpatterns = [
    path('api/signup/', InstructorSignupAPIView.as_view(), name='signup'),
    path('api/login/', InstructorLoginAPIView.as_view(), name='login'),
]

urlpatterns = [
    path('signup/instructor/', InstructorSignUpView.as_view(), name='instructor-signup'),
    path('login/instructor/', InstructorLoginView.as_view(), name='instructor-login')
] + api_urlpatterns
