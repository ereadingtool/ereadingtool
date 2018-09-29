from typing import List, TypeVar

from django.db import connection
from datetime import datetime as dt
from text.models import TextDifficulty


class StudentPerformance(object):
    def __init__(self, student: TypeVar('Student'), *args, **kwargs):
        """A report class for student performance that uses raw SQL."""
        super(StudentPerformance, self).__init__(*args, **kwargs)

        self.student = student

    def to_dict(self) -> List:
        performance = []

        student_text_readings = self.student.text_readings
        complete_state_name = student_text_readings.model.state_machine_cls.complete.name

        today = dt.now()

        first_of_current_month = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        first_of_next_month = today.replace(month=today.month+1).replace(day=1, hour=0, minute=0, second=0,
                                                                         microsecond=0)

        difficulty_slug = TextDifficulty.objects.get(name='Intermediate-Mid').slug

        with connection.cursor() as cursor:
            cursor.execute(self.query, [
                first_of_current_month,
                first_of_next_month,
                difficulty_slug,
                self.student.pk,
                complete_state_name,
                first_of_current_month,
                first_of_next_month
            ])

            result = cursor.fetchall()

            performance.append(result)

        return performance

    query = """
-- a count of completed texts for a particular student
-- and a list of total texts available to read
-- ending between a current date range
SELECT
  count.completed_texts,
  (SELECT COUNT(*) from text_text) as total_texts,
  (SELECT
  CAST(SUM(answered_questions.correct) AS FLOAT) / CAST(COUNT(DISTINCT question_id) AS FLOAT)
    as percentage_correct
FROM
  -- for each text reading and text section, a list of questions and whether they
  -- were answered correctly
  (SELECT
  text_reading_id,
  text_readings.student_id,
  text_section_id,
  text_readings_answers.question_id,
  answers.correct as correct,
  text_readings_answers.created_dt

  FROM text_reading_studenttextreadinganswers as text_readings_answers

    LEFT JOIN text_reading_studenttextreading text_readings
      on text_readings_answers.text_reading_id = text_readings.id

    LEFT JOIN question_answer as answers
      on answers.id  = text_readings_answers.answer_id

    LEFT JOIN text_text as texts
      on texts.id = text_readings.text_id

    LEFT JOIN text_textdifficulty text_difficulty
      on texts.difficulty_id = text_difficulty.id

  where text_readings.end_dt >= %s
  and text_readings.end_dt < %s
  and text_difficulty.slug = %s

  group by text_reading_id, text_section_id, answers.question_id
  order by text_readings_answers.created_dt) as answered_questions) as percentage_correct

FROM

  (SELECT COUNT(*) as completed_texts FROM
    (SELECT text_id
     from text_reading_studenttextreading text_readings
     where student_id = %s
     and state = %s
     and end_dt >= %s
     and end_dt < %s
     group by text_id) as s) as count;
    """
