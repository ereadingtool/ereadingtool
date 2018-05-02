from django.db import models
from django.contrib.auth.models import AbstractUser
from text.models import TextDifficulty


class ReaderUser(AbstractUser):
    pass


class Instructor(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)


class Student(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    difficulty_preference = models.ForeignKey(TextDifficulty, null=True, on_delete=models.SET_NULL,
                                              related_name='students')

    def to_dict(self):
        return {
            'id': self.pk,
            'difficulty_preference': self.difficulty_preference.slug if self.difficulty_preference else None
        }
