# Generated by Django 2.2 on 2021-01-28 23:55

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('text', '0005_auto_20201204_0136'),
        ('user', '0004_auto_20190424_0140'),
        ('report', '0002_auto_20210113_1855'),
    ]

    operations = [
        migrations.CreateModel(
            name='Flashcards',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('instance', models.IntegerField()),
                ('student', models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, related_name='report_student_flashcards', to='user.Student')),
                ('text_phrase', models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='text.TextPhrase')),
                ('text_section', models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='text.TextSection')),
            ],
            options={
                'unique_together': {('student', 'instance', 'text_phrase', 'text_section')},
            },
        ),
    ]
