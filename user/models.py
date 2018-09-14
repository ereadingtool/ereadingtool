from django.contrib.auth.models import AbstractUser

from django.db.models import ObjectDoesNotExist


class ReaderUser(AbstractUser):
    @property
    def profile(self):

        profile = None

        try:
            profile = self.student
        except ObjectDoesNotExist:
            profile = self.instructor

        return profile
