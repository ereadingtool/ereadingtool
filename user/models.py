from django.db import models
from django.contrib.auth.models import AbstractUser
from django.db.models import Q


class ReaderUser(AbstractUser):
    pass


class Instructor(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)

    def to_dict(self):
        return {
            'id': self.pk,
            'username': self.user.username,
            'texts': [text.to_instructor_summary_dict()
                      for text in self.created_texts.model.objects.filter(
                    Q(created_by=self) | Q(last_modified_by=self))]
        }

    def __str__(self):
        return self.user.username
