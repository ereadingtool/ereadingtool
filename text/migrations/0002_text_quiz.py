# Generated by Django 2.0.5 on 2018-05-17 21:49

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('quiz', '0001_initial'),
        ('text', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='text',
            name='quiz',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to='quiz.Quiz'),
        ),
    ]