from django.contrib import admin
from text.models import Text, TextDifficulty


class TextAdmin(admin.ModelAdmin):
    pass


class TextDifficultyAdmin(admin.ModelAdmin):
    pass


admin.register(TextDifficultyAdmin, TextDifficulty)
admin.register(TextAdmin, Text)

