from typing import AnyStr
from django.db import models


class URIs(models.Model):
    class Meta:
        abstract = True

    @classmethod
    def login_url(cls) -> AnyStr:
        raise NotImplementedError


class Profile(URIs):
    class Meta:
        abstract = True

    @classmethod
    def login_url(cls) -> AnyStr:
        raise NotImplementedError
