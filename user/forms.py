from django import forms
from django.contrib.auth import password_validation
from django.contrib.auth.forms import AuthenticationForm
from django.core.validators import validate_email
from django.utils.translation import ugettext_lazy as _

from text_old.models import TextDifficulty
from user.models import ReaderUser, Instructor, Student


class SignUpForm(forms.ModelForm):
    email = forms.EmailField(required=True)
    password = forms.CharField(required=True)
    confirm_password = forms.CharField(required=True)

    def clean_confirm_password(self):
        password = self.cleaned_data['password']
        confirm_password = self.cleaned_data['confirm_password']

        if password and confirm_password and password != confirm_password:
            raise forms.ValidationError(_("The two password fields didn't match."), code='password_mismatch')

        if password:
            try:
                password_validation.validate_password(password, self.instance)
            except forms.ValidationError as error:
                self.add_error('confirm_password', error)

        return confirm_password

    def clean_email(self):
        email = self.cleaned_data['email']

        validate_email(email)

        if ReaderUser.objects.filter(username=email).count():
            raise forms.ValidationError(_('Email address already exists.'), code='email_exists')

        return email

    def save(self, commit=True):
        reader_user = ReaderUser(username=self.cleaned_data['email'])
        reader_user.set_password(self.cleaned_data['password'])
        reader_user.save()

        profile = super(SignUpForm, self).save(commit=False)

        profile.user = reader_user
        profile.save()

        return profile


class InstructorSignUpForm(SignUpForm):
    class Meta:
        model = Instructor
        exclude = ('user',)


class StudentSignUpForm(SignUpForm):
    difficulty = forms.CharField(required=True)

    def clean_difficulty(self):
        if not TextDifficulty.objects.filter(slug=self.cleaned_data['difficulty']).count():
            raise forms.ValidationError(_("This difficulty does not exist."), code='difficulty_does_not_exist')

        return self.cleaned_data['difficulty']

    def save(self, commit=True):
        student = super(StudentSignUpForm, self).save(commit=commit)

        student.difficulty_preference = TextDifficulty.objects.get(slug=self.cleaned_data['difficulty'])
        student.save()

        return student

    class Meta:
        model = Student
        exclude = ('user', 'difficulty_preference',)


class InstructorLoginForm(AuthenticationForm):
    pass


class StudentLoginForm(AuthenticationForm):
    pass


class StudentForm(forms.ModelForm):
    class Meta:
        model = Student
        exclude = ('user',)
