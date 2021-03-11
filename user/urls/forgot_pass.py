from django.urls import path
from user.views.forgot_password import (PasswordResetAPIView, PasswordResetConfirmView, PasswordResetConfirmAPIView,
                                        PasswordResetView)

from user.views.forgot_password import ElmLoadPassResetConfirmView, ElmLoadPasswordResetView


api_urlpatterns = [
    path('api/password/reset', PasswordResetAPIView.as_view(), name='api-password-reset'),
    path('api/password/reset/confirm', PasswordResetConfirmAPIView.as_view(), name='api-password-reset-confirm'),
]

urlpatterns = [
    # TODO: This can be removed.
    path('load_elm_unauth_pass_reset_confirm.js',
         ElmLoadPassResetConfirmView.as_view(), name='load-elm-unauth-pass-reset-confirm'),

    # TODO: This can be removed.
    path('load_elm_unauth_pass_reset.js',
         ElmLoadPasswordResetView.as_view(), name='load-elm-unauth-pass-reset'),

    path('user/password_reset/', PasswordResetView.as_view(), name='password-reset'),
    path('user/password_reset/confirm/<str:uidb64>/<str:token>/',
         PasswordResetConfirmView.as_view(), name='password-reset-confirm')
] + api_urlpatterns