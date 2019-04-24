from django.db import models


class StudentResearchConsent(models.Model):
    pass


class StudentResearchConsentRange(models.Model):
    student_consent = models.ForeignKey(StudentResearchConsent, null=False, on_delete=models.CASCADE,
                                        related_name='consent_ranges')

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True, blank=True)
