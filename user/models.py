from django.db import models
from django.contrib.auth.models import AbstractUser


class ReaderUser(AbstractUser):
    pass


class Instructor(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)


class Student(models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
