from django.urls import path
from user.views.instructor import (InstructorAPIView, InstructorSignupAPIView, InstructorLoginAPIView, 
                                   InstructorLogoutAPIView, InstructorSignUpView, InstructorLoginView,
                                   InstructorProfileView, InstructorInviteAPIView, 
                                   ElmLoadJsInstructorProfileView, ElmLoadJsInstructorNoAuthView)


api_urlpatterns = [
<<<<<<< HEAD
    path('api/instructor/invite/', InstructorInviteAPIView.as_view(), name='api-instructor-invite'),
    path('api/instructor/signup/', InstructorSignupAPIView.as_view(), name='api-instructor-signup'),
    path('api/instructor/login/', InstructorLoginAPIView.as_view(), name='api-instructor-login'),
    path('api/instructor/logout/', InstructorLogoutAPIView.as_view(), name='api-instructor-logout'),
    path('api/instructor/<int:pk>/', InstructorAPIView.as_view(), name='api-instructor')
=======
    path('api/instructor/invite', InstructorInviteAPIView.as_view(), name='api-instructor-invite'),
    path('api/instructor/signup', InstructorSignupAPIView.as_view(), name='api-instructor-signup'),
    path('api/instructor/login', InstructorLoginAPIView.as_view(), name='api-instructor-login'),
    path('api/instructor/logout', InstructorLogoutAPIView.as_view(), name='api-instructor-logout'),
>>>>>>> 8f7061188744f72f023176c3cec924b2839ccc9a
]

elm_load_urlpatterns = [
    path('load_instructor_profile_elm.js', ElmLoadJsInstructorProfileView.as_view(),
         name='load-elm-instructor-profile'),

    path('load_elm_unauth_instructor.js', ElmLoadJsInstructorNoAuthView.as_view(), name='load-elm-unauth-instructor'),
]

urlpatterns = [
    path('signup/instructor/', InstructorSignUpView.as_view(), name='instructor-signup'),
    path('login/instructor/', InstructorLoginView.as_view(), name='instructor-login'),
    path('profile/instructor/', InstructorProfileView.as_view(), name='instructor-profile')
] + api_urlpatterns + elm_load_urlpatterns
