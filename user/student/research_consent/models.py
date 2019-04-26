from typing import AnyStr

from django.db import models
from django.utils import timezone


class StudentResearchConsent(models.Model):
    @property
    def latest_consent_range(self):
        try:
            return self.consent_ranges.order_by('-start_dt').filter()[0]
        except StudentResearchConsentRange.DoesNotExist:
            return None

    def on(self):
        if not self.latest_consent_range or self.latest_consent_range.end_dt is not None:
            self.consent_ranges.create()

    def off(self):
        if self.latest_consent_range and self.latest_consent_range.end_dt is None:
            self.latest_consent_range.end_dt = timezone.now()

            self.latest_consent_range.save()

    @property
    def active(self):
        if self.latest_consent_range and self.latest_consent_range.end_dt is not None:
            return True
        else:
            return False


class StudentResearchConsentRange(models.Model):
    student_consent = models.ForeignKey(StudentResearchConsent, null=False, on_delete=models.CASCADE,
                                        related_name='consent_ranges')

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> AnyStr:
        return f'{self.student_consent.student} consented to research on {self.start_dt}' + (f'and ended their consent '
                                                                                             f'on {self.end_dt}'
                                                                                             if self.end_dt else '')
