from django.db import models


class FlashcardSession(models.Model):
    class Meta:
        abstract = True

    """
    A model that keeps track of individual flashcard sessions.
    """

    start_dt = models.DateTimeField(null=False, auto_now_add=True)
    end_dt = models.DateTimeField(null=True)
