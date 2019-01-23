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

    @property
    def expiration_dt(self):
        return self.created + datetime.timedelta(days=settings.INVITATION_EXPIRY)

    @property
    def expired(self):
        return self.expiration_dt <= timezone.now()

    @classmethod
    def create(cls, email, instructor: 'Instructor', **kwargs):
        key = get_random_string(64).lower()

        invite = Invite.objects.create(email=email, key=key, inviter=instructor)

        return invite
