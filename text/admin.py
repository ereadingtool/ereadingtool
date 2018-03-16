from django.contrib import admin
from text.models import Text, TextDifficulty


class TextAdmin(admin.ModelAdmin):
    pass


class TextDifficultyAdmin(admin.ModelAdmin):
    readonly_fields = ('slug', )

    def save_model(self, request, obj, form, change):
        if not obj.slug:
            obj.slug = obj.name.lower().replace('-', '_')

        super(TextDifficultyAdmin, self).save_model(request, obj, form, change)


admin.site.register(TextDifficulty, TextDifficultyAdmin)
admin.site.register(Text, TextAdmin)

