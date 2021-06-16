from django.db import models
from text.models import Text
from user.student.models import Student
from django.utils import timezone

class FirstTimeCorrect(models.Model):
    # If a student id and text id exist in the model
    # then the student has attempted the text at least once
    student = models.ForeignKey(Student, related_name='student', on_delete=models.CASCADE)
    text = models.ForeignKey(Text, related_name='completed_text', on_delete=models.CASCADE)
    correct_answers = models.IntegerField(default=0)
    total_answers = models.IntegerField(default=0)
    end_dt = models.DateTimeField(null=False, auto_now_add=True)

    def to_json_schema():
        pass

    # CREATE TABLE "first_time_correct" (
    #     "id" integer NOT NULL,
    #     "student_id" integer NOT NULL,
    #     "text_id" integer NOT NULL,
    #     "correct_answers" integer NOT NULL,
    #     "total_answers" integer NOT NULL,
    #     "end_dt" datetime,
    #     PRIMARY KEY("id" AUTOINCREMENT)
    #     FOREIGN KEY("student_id") REFERENCES "user_student"("user_id") DEFERRABLE INITIALLY DEFERRED
    #     FOREIGN KEY("text_id") REFERENCES "text_text"("text_id") DEFERRABLE INITIALLY DEFERRED
    # )


class FirstTimeCorrectReport(object):
    def __init__(self, student: Student, *args, **kwargs):
        self.student = student
        self.queryset = FirstTimeCorrect.objects.filter(student=self.student)
