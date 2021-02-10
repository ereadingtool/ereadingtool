from django.db import models


class WriteLocked(Exception):
    pass


class Timestamped(models.Model):
    class Meta:
        abstract = True

    created_dt = models.DateTimeField(auto_now_add=True)
    modified_dt = models.DateTimeField(auto_now=True)


class WriteLockable(models.Model):
    class Meta:
        abstract = True

    write_locked = models.BooleanField(null=False, default=False)
    write_locker = models.ForeignKey('user.Instructor', null=True, on_delete=models.SET_NULL, related_name='editing')

    def save(self, *args, **kwargs):
        if self.__class__.objects.filter(pk=self.pk, write_locked=True).exists():
            raise WriteLocked()

        super(WriteLockable, self).save(*args, **kwargs)

    def is_locked(self) -> bool:
        return self.__class__.objects.filter(pk=self.pk, write_locked=True).exists()

    def lock(self, instructor) -> bool:
        locked = bool(self.__class__.objects.filter(pk=self.pk).update(write_locked=True, write_locker=instructor))

        self.write_locked = locked

        return locked

    def unlock(self) -> bool:
        unlocked = bool(self.__class__.objects.filter(pk=self.pk).update(write_locked=False, write_locker=None))

        self.write_locked = False if unlocked else True

        return not unlocked
