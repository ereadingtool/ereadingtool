# Generated by Django 2.2 on 2021-05-14 21:29

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('user', '0007_auto_20210514_1849'),
    ]

    operations = [
        migrations.AddField(
            model_name='student',
            name='dashboard_last_updated',
            field=models.DateTimeField(null=True),
        ),
    ]