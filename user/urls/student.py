from django.urls import path
from user.views.student import (StudentSignUpView, StudentSignupAPIView, StudentProfileView,
                                StudentLoginView, StudentLoginAPIView)


api_urlpatterns = [
    path('api/student/signup/', StudentSignupAPIView.as_view(), name='api-student-signup'),
    path('api/student/login/', StudentLoginAPIView.as_view(), name='api-student-login'),
]

urlpatterns = [
    path('signup/student/', StudentSignUpView.as_view(), name='student-signup'),
    path('login/student/', StudentLoginView.as_view(), name='student-login'),
    path('profile/student/', StudentProfileView.as_view(), name='student-profile')

] + api_urlpatterns
