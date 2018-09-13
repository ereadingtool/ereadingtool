from django.urls import path
from user.views.forgot_password import PasswordResetAPIView, PasswordResetConfirmView


api_urlpatterns = [
    path('api/password/reset/', PasswordResetAPIView.as_view(), name='api-password-reset')
]

urlpatterns = [
    path('user/password_reset_confirm/<str:uidb64>/<str:token>/',
         PasswordResetConfirmView.as_view(), name='password-reset-confirm')
] + api_urlpatterns
