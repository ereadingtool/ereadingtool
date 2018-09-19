from typing import Optional, TypeVar
from django.db import models

from django.urls import reverse_lazy

from text.models import TextDifficulty
from user.models import ReaderUser

from user.mixins.models import Profile


class Student(Profile, models.Model):
    user = models.OneToOneField(ReaderUser, on_delete=models.CASCADE)
    difficulty_preference = models.ForeignKey(TextDifficulty, null=True, on_delete=models.SET_NULL,
                                              related_name='students')

    login_url = reverse_lazy('student-login')

    def to_dict(self):
        difficulties = [(text_difficulty.slug, text_difficulty.name)
                        for text_difficulty in TextDifficulty.objects.all()]

        # difficulty_preference can be null
        difficulties.append(('', ''))

        return {
            'id': self.pk,
            'username': self.user.username,
            'difficulty_preference': [self.difficulty_preference.slug, self.difficulty_preference.name]
            if self.difficulty_preference else None,
            'difficulties': difficulties,
            'text_reading': [text_reading.to_dict() for text_reading in self.text_readings.all()]
        }

    def sections_complete_for(self, text: Optional[TypeVar('Text')]) -> int:
        sections_complete = 0

        if self.text_readings.filter(text=text).exists():
            current_text_reading = self.text_readings.exclude(state='complete').get(text=text)

            if not current_text_reading.state_machine.is_intro:
                sections_complete = current_text_reading.current_section.order+1

        return sections_complete

    def __str__(self):
        return self.user.username
