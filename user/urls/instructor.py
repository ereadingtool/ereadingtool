from django.urls import path
from user.views.instructor import (InstructorAPIView, InstructorSignupAPIView, InstructorLoginAPIView, 
                                   InstructorLogoutAPIView, InstructorSignUpView, InstructorLoginView,
                                   InstructorProfileView, InstructorInviteAPIView, 
                                   ElmLoadJsInstructorProfileView, ElmLoadJsInstructorNoAuthView)


api_urlpatterns = [
    path('api/instructor/invite', InstructorInviteAPIView.as_view(), name='api-instructor-invite'),
    path('api/instructor/signup', InstructorSignupAPIView.as_view(), name='api-instructor-signup'),
    path('api/instructor/login', InstructorLoginAPIView.as_view(), name='api-instructor-login'),
    # TODO: this route is unused since the client side simply invalidates the JWT
    path('api/instructor/logout', InstructorLogoutAPIView.as_view(), name='api-instructor-logout'),
    path('api/instructor/<int:pk>', InstructorAPIView.as_view(), name='api-instructor'),
    path('api/instructor/<int:pk>', InstructorAPIView.as_view(), name='api-instructor')
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
