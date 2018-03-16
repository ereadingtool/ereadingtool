from django.contrib import admin
from text.models import Text, TextDifficulty


class TextAdmin(admin.ModelAdmin):
    pass


class TextDifficultyAdmin(admin.ModelAdmin):
    pass


admin.site.register(TextDifficulty, TextDifficultyAdmin)
admin.site.register(Text, TextAdmin)

