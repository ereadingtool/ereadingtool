# Generated by Django 2.1.2 on 2018-11-07 03:01

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('text', '0018_auto_20181107_0252'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='textword',
            name='definitions',
        ),
    ]