# Generated by Django 3.2.7 on 2021-09-14 15:01

import cloudinary.models
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('team', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Member',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('name', models.CharField(max_length=100)),
                ('title', models.CharField(max_length=100)),
                ('about', models.TextField(blank=True)),
                ('picture', cloudinary.models.CloudinaryField(max_length=255, verbose_name='Image')),
            ],
        ),
        migrations.DeleteModel(
            name='Team',
        ),
    ]
