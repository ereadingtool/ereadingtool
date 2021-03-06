# Generated by Django 2.1.5 on 2019-03-06 01:40

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('text_reading', '0001_initial'),
        ('text', '0002_auto_20190306_0140'),
        ('question', '0002_auto_20190306_0140'),
        ('user', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='studenttextreading',
            name='student',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='text_readings', to='user.Student'),
        ),
        migrations.AddField(
            model_name='studenttextreading',
            name='text',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='text.Text'),
        ),
        migrations.AddField(
            model_name='instructortextreadinganswers',
            name='answer',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='question.Answer'),
        ),
        migrations.AddField(
            model_name='instructortextreadinganswers',
            name='question',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='question.Question'),
        ),
        migrations.AddField(
            model_name='instructortextreadinganswers',
            name='text_reading',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='text_reading_answers', to='text_reading.InstructorTextReading'),
        ),
        migrations.AddField(
            model_name='instructortextreadinganswers',
            name='text_section',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='text.TextSection'),
        ),
        migrations.AddField(
            model_name='instructortextreading',
            name='current_section',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='text.TextSection'),
        ),
        migrations.AddField(
            model_name='instructortextreading',
            name='instructor',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='text_readings', to='user.Instructor'),
        ),
        migrations.AddField(
            model_name='instructortextreading',
            name='text',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='text.Text'),
        ),
        migrations.AlterUniqueTogether(
            name='studenttextreadinganswers',
            unique_together={('text_reading', 'text_section', 'question', 'answer')},
        ),
        migrations.AlterUniqueTogether(
            name='instructortextreadinganswers',
            unique_together={('text_reading', 'text_section', 'question', 'answer')},
        ),
    ]
