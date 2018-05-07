from django.urls import path
from user.views.student import (StudentSignUpView, StudentSignupAPIView, StudentProfileView, StudentAPIView,
                                StudentLoginView, StudentLoginAPIView, StudentLoadElm)


api_urlpatterns = [
    path('api/student/signup/', StudentSignupAPIView.as_view(), name='api-student-signup'),
    path('api/student/login/', StudentLoginAPIView.as_view(), name='api-student-login'),
    path('api/student/<int:pk>/', StudentAPIView.as_view(), name='api-student'),
]

urlpatterns = [
    path('student/load_elm.js', StudentLoadElm.as_view(), name='student-elm'),

    path('signup/student/', StudentSignUpView.as_view(), name='student-signup'),
    path('login/student/', StudentLoginView.as_view(), name='student-login'),
    path('profile/student/', StudentProfileView.as_view(), name='student-profile')

] + api_urlpatterns
