from django.db import models
from django.contrib.auth.models import AbstractUser
from text.models import TextDifficulty


class ReaderUser(AbstractUser):
    pass


class Instructor(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)

    def to_dict(self):
        return {
            'id': self.pk,
            'username': self.user.username
        }

    def __str__(self):
        return self.user.username
