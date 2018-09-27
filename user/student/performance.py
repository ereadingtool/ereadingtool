from typing import Dict, TypeVar

from django.db import models


class StudentPerformance(object):
    def __init__(self, student: TypeVar('Student'), *args, **kwargs):
        """"""
        super(StudentPerformance, self).__init__(*args, **kwargs)

        self.student = student

    def to_dict(self) -> Dict:
        performance = {}

        student_text_readings = self.student.text_readings
        complete_state_name = student_text_readings.model.state_machine_cls.complete.name

        student_text_readings.filter(state=complete_state_name)

        return performance
