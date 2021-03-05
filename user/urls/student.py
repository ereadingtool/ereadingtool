from report.models import StudentFlashcardsCSV
from django.urls import path
from user.views.student import (StudentSignUpView, StudentSignupAPIView, StudentProfileView, StudentAPIView,
                                StudentAPIConsentToResearchView, StudentLoginView, StudentLoginAPIView,
                                StudentLogoutAPIView, StudentFlashcardView, ElmLoadJsStudentProfileView,
                                ElmLoadStudentSignUpView, ElmLoadJsStudentLoginView)

from user.views.student_performance import StudentPerformancePDFView
from user.views.student_flashcards import StudentFlashcardsPDFView, StudentFlashcardsCSVView


api_urlpatterns = [
    path('api/student/signup', StudentSignupAPIView.as_view(), name='api-student-signup'),
    path('api/student/login', StudentLoginAPIView.as_view(), name='api-student-login'),
    # TODO: this route is unused since the client side simply invalidates the JWT
    path('api/student/logout', StudentLogoutAPIView.as_view(), name='api-student-logout'),
    path('api/student/<int:pk>', StudentAPIView.as_view(), name='api-student'),
    path('api/student/<int:pk>/consent_to_research', StudentAPIConsentToResearchView.as_view(),
         name='api-student-research-consent')
]

# TODO: Tests rely on these
elm_load_urlpatterns = [
    path('load_elm_student.js', ElmLoadJsStudentProfileView.as_view(), name='load-elm-student'),
    path('load_elm_unauth_student_login.js', ElmLoadJsStudentLoginView.as_view(),
         name='load-elm-unauth-student-login'),
    path('load_elm_unauth_student_signup.js', ElmLoadStudentSignUpView.as_view(),
         name='load-elm-unauth-student-signup'),
]

urlpatterns = [
    path('profile/student/<int:pk>/performance_report.pdf', StudentPerformancePDFView.as_view(),
         name='student-performance-pdf-link'),
    path('profile/student/<int:pk>/words.pdf', StudentFlashcardsPDFView.as_view(),
         name='student-flashcards-pdf-link'),
    path('profile/student/<int:pk>/words.csv', StudentFlashcardsCSVView.as_view(),
         name='student-flashcards-csv-link'),
    path('signup/student', StudentSignUpView.as_view(), name='student-signup'),
    path('login/student', StudentLoginView.as_view(), name='student-login'),
    path('profile/student', StudentProfileView.as_view(), name='student-profile'),
    path('flashcards/student', StudentFlashcardView.as_view(), name='student-flashcards'),
] + api_urlpatterns + elm_load_urlpatterns
