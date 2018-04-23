from django import forms

from user.models import ReaderUser, Instructor, Student
from django.contrib.auth.forms import AuthenticationForm
from django.utils.translation import ugettext_lazy as _
from django.core.validators import validate_email


class SignUpForm(forms.ModelForm):
    email = forms.EmailField(required=True)
    password = forms.CharField(required=True)
    confirm_password = forms.CharField(required=True)

    def clean_email(self):
        email = self.cleaned_data['email']

        validate_email(email)

        if ReaderUser.objects.filter(username=email).count():
            raise forms.ValidationError(_('Email address already exists.'), code='email_exists')

        return email

    def save(self, commit=True):
        self.cleaned_data['user'] = ReaderUser(username=self.cleaned_data['email'],
                                               password=self.cleaned_data['password'])

        self.cleaned_data['user'].save()

        user = super(SignUpForm, self).save(commit=False)

        user.user = self.cleaned_data['user']
        user.save()

        return user


class InstructorSignUpForm(SignUpForm):
    class Meta:
        model = Instructor
        exclude = ('user',)


class StudentSignUpForm(SignUpForm):
    class Meta:
        model = Student
        exclude = ('user',)


class InstructorLoginForm(AuthenticationForm):
    pass


class StudentLoginForm(forms.ModelForm):
    class Meta:
        model = Student
        exclude = ('user',)
