from typing import AnyStr

from django.db import models
from django.utils import timezone


class StudentDashboardUser(models.Model):
    @property
    def latest_connection_range(self):
        try:
            return self.dashboard_connection_ranges.order_by('-start_dt').filter()[0]
        except IndexError:
            return None

    def on(self):
        if not self.latest_connection_range or self.latest_connection_range.end_dt is not None:
            self.dashboard_connection_ranges.create()

    def off(self):
        if self.latest_connection_range and self.latest_connection_range.end_dt is None:
            latest_connection_range = self.latest_connection_range

            latest_connection_range.end_dt = timezone.now()

            latest_connection_range.save()

    @property
    def active(self):
        if self.latest_connection_range and self.latest_connection_range.end_dt is None:
            return True
        else:
            return False


class StudentDashboardUserRange(models.Model):
    student_dashboard_user = models.ForeignKey(StudentDashboardUser, null=False, on_delete=models.CASCADE,
                                               related_name='dashboard_connection_ranges')

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> AnyStr:
        return f"{self.student_dashboard_user.student} affirmed they're a dashboard user on {self.start_dt}" \
               + (f" and ended this connection on {self.end_dt}" if self.end_dt else "")