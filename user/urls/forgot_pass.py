from django.urls import path
from user.views.forgot_password import (PasswordResetAPIView, PasswordResetConfirmView, PasswordResetConfirmAPIView,
                                        PasswordResetView)


api_urlpatterns = [
    path('api/password/reset/', PasswordResetAPIView.as_view(), name='api-password-reset'),
    path('api/password/reset/confirm/', PasswordResetConfirmAPIView.as_view(), name='api-password-reset-confirm')
]

urlpatterns = [
    path('user/password_reset/', PasswordResetView.as_view(), name='password-reset'),
    path('user/password_reset/confirm/<str:uidb64>/<str:token>/',
         PasswordResetConfirmView.as_view(), name='password-reset-confirm')
] + api_urlpatterns
