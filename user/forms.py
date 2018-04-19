from django.forms import ModelForm

from user.models import Instructor, Student


class SignUpForm(ModelForm):
    class Meta:
        fields = ('email', 'password', 'verify_password',)

    def full_clean(self):
        super(SignUpForm, self).full_clean()


class InstructorSignUpForm(SignUpForm):
    class Meta:
        model = Instructor
        exclude = ('user',)


class StudentSignUpForm(SignUpForm):
    class Meta:
        model = Student
        exclude = ('user',)


class InstructorLoginForm(ModelForm):
    class Meta:
        model = Instructor
        exclude = ('user',)


class StudentLoginForm(ModelForm):
    class Meta:
        model = Student
        exclude = ('user',)
