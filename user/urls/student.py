from django.urls import path
from user.views.student import (StudentSignUpView, StudentSignupAPIView, StudentProfileView, StudentAPIView,
                                StudentLoginView, StudentLoginAPIView, StudentLogoutAPIView, ElmLoadJsStudentView,
                                ElmLoadStudentSignUpView)

from user.views.student_performance import StudentPerformancePDFView

api_urlpatterns = [
    path('api/student/signup/', StudentSignupAPIView.as_view(), name='api-student-signup'),
    path('api/student/login/', StudentLoginAPIView.as_view(), name='api-student-login'),
    path('api/student/logout/', StudentLogoutAPIView.as_view(), name='api-student-logout'),
    path('api/student/<int:pk>/', StudentAPIView.as_view(), name='api-student'),
]

elm_load_urlpatterns = [
    path('load_elm.js', ElmLoadJsStudentView.as_view(), name='load-elm-student'),
    path('load_elm_unauth_student.js', ElmLoadStudentSignUpView.as_view(), name='load-elm-unauth-student-signup'),
]

urlpatterns = [
    path('profile/student/<int:pk>/performance_report.pdf', StudentPerformancePDFView.as_view(),
         name='student-performance-pdf-link'),
    path('signup/student/', StudentSignUpView.as_view(), name='student-signup'),
    path('login/student/', StudentLoginView.as_view(), name='student-login'),
    path('profile/student/', StudentProfileView.as_view(), name='student-profile'),
] + api_urlpatterns + elm_load_urlpatterns
