# Generated by Django 2.2 on 2021-04-20 20:47

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('user', '0004_auto_20190424_0140'),
        ('text', '0009_auto_20210407_1815'),
    ]

    operations = [
        migrations.RenameField(
            model_name='textrating',
            old_name='rating',
            new_name='vote',
        ),
        migrations.AlterUniqueTogether(
            name='textrating',
            unique_together={('student', 'text', 'vote')},
        ),
    ]
