from typing import Dict, Any

import datetime

from django.conf import settings
from django.db import models
from django.utils import timezone
from django.utils.crypto import get_random_string


class Invite(models.Model):
    email = models.EmailField(unique=True, max_length=256)
    created = models.DateTimeField(default=timezone.now)
    key = models.CharField(max_length=64, unique=True)

    inviter = models.ForeignKey('user.Instructor', null=False, blank=False, on_delete=models.CASCADE)

    expiry = datetime.timedelta(days=settings.INVITATION_EXPIRY)

    def __str__(self):
        return f'{self.inviter} invited {self.email} on {self.created}'

    @property
    def expiration_dt(self):
        return self.created + self.expiry

    @property
    def expired(self):
        return self.expiration_dt <= timezone.now()

    @classmethod
    def create(cls, email, inviter: Any, **kwargs):
        key = get_random_string(64).lower()

        invite = Invite.objects.create(email=email, key=key, inviter=inviter)

        return invite

    def to_dict(self) -> Dict:
        return {
            'email': self.email,
            'invite_code': self.key,
        }
