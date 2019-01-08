from django import forms
from django.contrib.auth import password_validation
from django.contrib.auth.forms import AuthenticationForm as BaseAuthenticationForm
from django.core.validators import validate_email

from django.utils.translation import ugettext_lazy as _

from text.models import TextDifficulty
from user.models import ReaderUser

from user.instructor.models import Instructor
from user.student.models import Student


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

        if ReaderUser.objects.filter(username=email).exists():
            raise forms.ValidationError(_('Email address already exists.'), code='email_exists')

        return email

    def save(self, commit=True):
        reader_user = ReaderUser(username=self.cleaned_data['email'], email=self.cleaned_data['email'])
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
    class Meta:
        model = Student
        exclude = ('user', 'difficulty_preference', 'flashcards',)

    difficulty = forms.CharField(required=True)

    def clean_difficulty(self):
        if not TextDifficulty.objects.filter(slug=self.cleaned_data['difficulty']).exists():
            raise forms.ValidationError(_("This difficulty does not exist."), code='difficulty_does_not_exist')

        return self.cleaned_data['difficulty']

    def save(self, commit=True):
        student = super(StudentSignUpForm, self).save(commit=commit)

        student.difficulty_preference = TextDifficulty.objects.get(slug=self.cleaned_data['difficulty'])
        student.save()

        return student


class AuthenticationForm(BaseAuthenticationForm):
    def clean_username(self):
        username = self.cleaned_data['username']

        # we prefer the e-mail address for logging in but Django can only auth by username, so we swap the two
        user = ReaderUser.objects.filter(email__iexact=self.cleaned_data['username'])

        if user.exists():
            try:
                username = user.get().username
            except ReaderUser.MultipleObjectsReturned:
                pass

        return username


class InstructorLoginForm(AuthenticationForm):
    pass


class StudentLoginForm(AuthenticationForm):
    pass


class StudentForm(forms.ModelForm):
    username = forms.CharField(validators=[ReaderUser.username_validator], required=False)

    def __init__(self, *args, **kwargs):
        super(StudentForm, self).__init__(*args, **kwargs)

        self.fields['difficulty_preference'].required = False

    def save(self, commit=True):
        student = super(StudentForm, self).save(commit=commit)

        student.user.username = self.cleaned_data['username']
        student.user.save()

        return student

    class Meta:
        model = Student
        exclude = ('user',)
