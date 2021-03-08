# Generated by Django 2.1.5 on 2019-03-20 18:56

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('flashcards', '0007_auto_20190320_1844'),
    ]

    operations = [
        migrations.AlterField(
            model_name='studentflashcardsession',
            name='current_flashcard',
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.DO_NOTHING, related_name='session', to='flashcards.StudentFlashcard'),
        ),
        migrations.AlterField(
            model_name='studentflashcardsession',
            name='end_dt',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
