from typing import AnyStr

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.utils.http import urlsafe_base64_decode

UserModel = get_user_model()

INTERNAL_RESET_URL_TOKEN = 'set-password'
INTERNAL_RESET_SESSION_TOKEN = '_password_reset_token'


def get_user(uidb64: AnyStr) -> UserModel:
    try:
        # urlsafe_base64_decode() decodes to bytestring
        uid = urlsafe_base64_decode(uidb64).decode()
        user = UserModel._default_manager.get(pk=uid)

    except (TypeError, ValueError, OverflowError, UserModel.DoesNotExist, ValidationError):
        user = None

    return user
