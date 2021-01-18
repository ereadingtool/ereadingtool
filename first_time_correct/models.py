from django.db import models
from text.models import Text
from user.student.models import Student

class FirstTimeCorrect(models.Model):
    # If a student id and text id exist in the model
    # then the student has attempted the text at least once
    student = models.ForeignKey(Student, related_name='student', on_delete=models.CASCADE)
    text = models.ForeignKey(Text, related_name='completed_text', on_delete=models.CASCADE)
    num_correct = models.IntegerField()


    def to_json_schema():
        pass

    # CREATE TABLE "first_time_correct" (
    #     "id" integer NOT NULL,
    #     "student_id" integer NOT NULL,
    #     "text_id" integer NOT NULL,
    #     "num_correct" integer NOT NULL,
    #     PRIMARY KEY("id" AUTOINCREMENT)
    #     FOREIGN KEY("student_id") REFERENCES "user_student"("user_id") DEFERRABLE INITIALLY DEFERRED
    #     FOREIGN KEY("text_id") REFERENCES "text_text"("text_id") DEFERRABLE INITIALLY DEFERRED
    # )


class FirstTimeCorrectReport(object):
    def __init__(self, student: Student, *args, **kwargs):
        self.student = student
        self.queryset = FirstTimeCorrect.objects.filter(student=self.student)