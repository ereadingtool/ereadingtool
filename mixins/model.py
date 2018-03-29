from django.db import models


class Timestamped(models.Model):
    class Meta:
        abstract = True

    created_dt = models.DateTimeField(auto_now_add=True)
    modified_dt = models.DateTimeField(auto_now=True)
