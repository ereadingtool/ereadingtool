# Generated by Django 2.2 on 2021-04-07 02:26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('text', '0006_textsection_translation_service_processed'),
    ]

    operations = [
        migrations.AddField(
            model_name='text',
            name='rating',
            field=models.IntegerField(default=0),
        ),
    ]
