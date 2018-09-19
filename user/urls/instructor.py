from django.urls import path
from user.views.instructor import (InstructorSignupAPIView, InstructorLoginAPIView, InstructorLogoutAPIView, 
                                   InstructorSignUpView, InstructorLoginView, InstructorProfileView,
                                   ElmLoadJsInstructorView)


api_urlpatterns = [
    path('api/instructor/signup/', InstructorSignupAPIView.as_view(), name='api-instructor-signup'),
    path('api/instructor/login/', InstructorLoginAPIView.as_view(), name='api-instructor-login'),
    path('api/instructor/logout/', InstructorLogoutAPIView.as_view(), name='instructor-logout'),
]

elm_load_urlpatterns = [
    path('load_elm.js', ElmLoadJsInstructorView.as_view(), name='load-elm-instructor'),
]

urlpatterns = [
    path('signup/instructor/', InstructorSignUpView.as_view(), name='instructor-signup'),
    path('login/instructor/', InstructorLoginView.as_view(), name='instructor-login'),
    path('profile/instructor/', InstructorProfileView.as_view(), name='instructor-profile')
] + api_urlpatterns + elm_load_urlpatterns
