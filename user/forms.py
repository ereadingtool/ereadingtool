from django import forms

from user.models import ReaderUser, Instructor, Student
from django.contrib.auth.forms import AuthenticationForm
from django.utils.translation import ugettext_lazy as _
from django.core.validators import validate_email
from django.contrib.auth import password_validation


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

    class Meta:
        model = Student
        exclude = ('user',)


class InstructorLoginForm(AuthenticationForm):
    pass


class StudentLoginForm(AuthenticationForm):
    pass
