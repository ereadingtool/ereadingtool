from django.db import models
from django.db.models import Q
from django.urls import reverse_lazy

from user.models import ReaderUser
from user.mixins.models import Profile


class Instructor(Profile, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)

    login_url = reverse_lazy('instructor-login')

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

