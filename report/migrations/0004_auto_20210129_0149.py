# Generated by Django 2.2 on 2021-01-29 01:49

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('text', '0005_auto_20201204_0136'),
        ('user', '0004_auto_20190424_0140'),
        ('report', '0003_flashcards'),
    ]

    operations = [
        migrations.RenameField(
            model_name='flashcards',
            old_name='text_phrase',
            new_name='phrase',
        ),
        migrations.AlterUniqueTogether(
            name='flashcards',
            unique_together={('student', 'instance', 'phrase', 'text_section')},
        ),
    ]
