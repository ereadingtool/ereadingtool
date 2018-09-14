from django.db import models


class URIs(models.Model):
    class Meta:
        abstract = True

    def login_url(self):
        raise NotImplementedError
