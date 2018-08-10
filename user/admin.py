from django.contrib import admin
from user.models import Instructor
from user.student.models import Student


class InstructorAdmin(admin.ModelAdmin):
    pass


class StudentAdmin(admin.ModelAdmin):
    pass


admin.site.register(Instructor, InstructorAdmin)
admin.site.register(Student, StudentAdmin)
