import json

from typing import TypeVar, Dict, Union

from django import forms
from django.contrib.auth import login, logout
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.template import loader
from django.urls import reverse

from django.views.generic import TemplateView, View

from text.models import TextDifficulty
from user.forms import AuthenticationForm, StudentSignUpForm, StudentForm, StudentConsentForm
from user.student.models import Student
from user.views.api import APIView
from user.views.mixin import ProfileView
from django.contrib.auth.mixins import LoginRequiredMixin
from mixins.view import ElmLoadJsStudentBaseView, NoAuthElmLoadJsView
from django.http import JsonResponse

from jwt_auth.views import jwt_encode_token, jwt_get_json_with_token

from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

Form = TypeVar('Form', bound=forms.Form)


# TODO: I think that this is marked for deletion (remove loader import once done)
class ElmLoadJsStudentProfileView(ElmLoadJsStudentBaseView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsStudentProfileView, self).get_context_data(**kwargs)

        student_profile = None

        try:
            student_profile = self.request.user.student
        except Student.DoesNotExist:
            pass

        performance_report_html = loader.render_to_string('student_performance_report.html', {
            'performance_report': student_profile.performance.to_dict()
        })

        performance_report_pdf_link = reverse('student-performance-pdf-link', kwargs={'pk': student_profile.pk})

        context['elm']['student_profile'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(student_profile.to_dict())
        }

        context['elm']['performance_report'] = {'quote': False, 'safe': True, 'value': {
            'html': performance_report_html,
            'pdf_link': performance_report_pdf_link,
        }}

        context['elm']['flashcards'] = {'quote': False, 'safe': True, 'value': [
            card.phrase.phrase for card in student_profile.flashcards.all()
        ] if student_profile.flashcards else None}

        try:
            welcome = self.request.session['welcome']['student_profile']
        except KeyError:
            welcome = False

        try:
            if welcome:
                student_session = self.request.session['welcome']

                del student_session['student_profile']

                self.request.session['welcome'] = student_session
        except KeyError:
            pass

        context['elm']['welcome'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(welcome)
        }

        context['elm']['consenting_to_research'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(student_profile.is_consenting_to_research)
        }

        def uri_to_elm(url):
            return {
                'quote': True,
                'safe': True,
                'value': url
            }

        context['elm'].update({
            'student_endpoint': uri_to_elm(reverse('api-student', kwargs={'pk': student_profile.pk})),
            'student_username_validation_uri': uri_to_elm(reverse('username-api')),
            'student_research_consent_uri': uri_to_elm(reverse('api-student-research-consent',
                                                               kwargs={'pk': student_profile.pk}))
        })

        return context


class ElmLoadStudentSignUpView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadStudentSignUpView, self).get_context_data(**kwargs)

        context['elm']['difficulties'] = {'quote': False, 'safe': True,
                                          'value':
                                              json.dumps([(text_difficulty.slug, text_difficulty.name)
                                                          for text_difficulty in TextDifficulty.objects.all()])}

        def url_elm_value(url):
            return {'quote': True, 'safe': True, 'value': url}

        context['elm'].update({
            'user_type': {'quote': True, 'safe': True, 'value': 'student'},
            'student_signup_uri': url_elm_value(reverse('api-student-signup')),
            'signup_page_url': url_elm_value(reverse('student-signup')),

            'login_uri': url_elm_value(reverse('api-student-login')),
            'login_page_url': url_elm_value(reverse('instructor-login')),

            'reset_pass_endpoint': url_elm_value(reverse('api-password-reset')),
            'forgot_pass_endpoint': url_elm_value(reverse('api-password-reset-confirm')),
            'forgot_password_url': url_elm_value(reverse('password-reset')),
            'acknowledgements_url': url_elm_value(reverse('acknowledgements')),
            'about_url': url_elm_value(reverse('about'))
        })

        return context


class ElmLoadJsStudentLoginView(NoAuthElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(ElmLoadJsStudentLoginView, self).get_context_data(**kwargs)

        def url_elm_value(url):
            return {'quote': True, 'safe': True, 'value': url}

        context['elm'].update({
            'user_type': {'quote': True, 'safe': True, 'value': 'student'},
            'signup_uri': url_elm_value(reverse('api-student-signup')),
            'signup_page_url': url_elm_value(reverse('student-signup')),

            'login_uri': url_elm_value(reverse('api-student-login')),
            'login_page_url': url_elm_value(reverse('instructor-login')),

            'reset_pass_endpoint': url_elm_value(reverse('api-password-reset')),
            'forgot_pass_endpoint': url_elm_value(reverse('api-password-reset-confirm')),
            'forgot_password_url': url_elm_value(reverse('password-reset')),

            'acknowledgements_url': url_elm_value(reverse('acknowledgements')),
            'about_url': url_elm_value(reverse('about'))
        })

        return context


class StudentView(ProfileView):
    profile_model = Student
    login_url = Student.login_url

# Method decorator required for PUT method
@method_decorator(csrf_exempt, name='dispatch')
class StudentAPIConsentToResearchView(LoginRequiredMixin, APIView):
    # returns permission denied HTTP message rather than redirect to login

    def get(self, request: HttpRequest, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).count():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk']) 

        return HttpResponse(json.dumps({'consented': student.is_consenting_to_research}))

    def form(self, request: HttpRequest, params: Dict, **kwargs) -> forms.ModelForm:
        return StudentConsentForm(params, **kwargs)

    def put_error(self, status, errors: Dict) -> HttpResponse:
        return HttpResponse(json.dumps(errors), status=status)

    def put_success(self, request: HttpRequest, student_form: Union[Form, forms.ModelForm]) -> HttpResponse:
        student = student_form.save()

        return HttpResponse(json.dumps({'consented': student.is_consenting_to_research}))


# Method decorator required for PUT method
@method_decorator(csrf_exempt, name='dispatch')
class StudentAPIView(LoginRequiredMixin, APIView):
    def form(self, request: HttpRequest, params: Dict, **kwargs) -> forms.ModelForm:
        return StudentForm(params, **kwargs)

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).count():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponseForbidden()

        student_dict = student.to_dict()

        try:
            performance_report = student.performance.to_dict()
        except:
            performance_report = None

        return HttpResponse(json.dumps({
            'profile': student_dict,
            'performance_report': performance_report
        }))
        
    def post_success(self, request: HttpRequest, form: Form) -> HttpResponse:
        raise NotImplementedError

    def put_error(self, status, errors: Dict) -> HttpResponse:
        return HttpResponse(json.dumps(errors), status=status)

    def put_success(self, request: HttpRequest, student_form: Union[Form, forms.ModelForm]) -> HttpResponse:
        student = student_form.save()
        
        student_dict = student.to_dict()

        return HttpResponse(json.dumps({
            'profile': student_dict
        }))


class StudentSignupAPIView(APIView):
    def form(self, request: HttpRequest, params: Dict) -> forms.ModelForm:
        return StudentSignUpForm(params)

    def post_success(self, request: HttpRequest, student_signup_form: Form) -> HttpResponse:
        student = student_signup_form.save()

        request.session['welcome'] = {
            'student_profile': True,
            'student_search': True
        }

        return HttpResponse(json.dumps({'id': student.pk, 'redirect': reverse('student-login')}))


class StudentLogoutAPIView(LoginRequiredMixin, APIView):
    def post(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        logout(request)

        return HttpResponse(json.dumps({'redirect': reverse('student-login')}))


class StudentLoginAPIView(APIView):
    """
    This class handles the student's login by returning a JWT to the client 
    """
    def form(self, request: HttpRequest, params: Dict) -> Form:
        # This class appears to just be an `AuthenticationForm` since it simply passes
        return AuthenticationForm(request, params)

    def post_success(self, request: HttpRequest, student_login_form: Form) -> JsonResponse:
        """
        Form validation is done in user/views/api.py so we assume the form fields are valid.
        This function will get the user `pk` and generate a token using that value. The token's 
        life span can be changed in settings.py by way of `JWT_EXPIRATION_DELTA`
        Args: HttpRequest: presumably a POST. Form: a Django type holding form data, aliased up top.
        Returns: JsonResponse containing the new JWT
        """        
        reader_user = student_login_form.get_user()

        token = jwt_encode_token(
            # cleaned_data sanitizes the form fields https://docs.djangoproject.com/en/3.1/ref/forms/api/#accessing-clean-data
            # orig_iat means "original issued at" https://tools.ietf.org/html/rfc7519
            reader_user, student_login_form.cleaned_data.get('orig_iat') 
        )

        # payload now contains string 'Bearer', the token, and the expiration time JWT_EXPIRATION_DELTA (in seconds)
        jwt_payload = jwt_get_json_with_token(token)

        # manually add the field `[id]` to the jwt payload
        jwt_payload['id'] = reader_user.student.pk

        # return to the dispatcher to send out an HTTP response
        return JsonResponse(jwt_payload)


class StudentSignUpView(TemplateView):
    template_name = 'student/signup.html'

    def get_context_data(self, **kwargs) -> Dict:
        context = super(StudentSignUpView, self).get_context_data(**kwargs)

        context['title'] = 'Student Signup'

        context['difficulties'] = json.dumps([(text_difficulty.slug, text_difficulty.name)
                                              for text_difficulty in TextDifficulty.objects.all()])

        return context


# TODO
class StudentLoginView(TemplateView):
    template_name = 'student/login.html'

    def get_context_data(self, **kwargs):
        context = super(StudentLoginView, self).get_context_data(**kwargs)

        context['title'] = 'Student Login'

        return context


# TODO
class StudentProfileView(StudentView, TemplateView):
    template_name = 'student/profile.html'

    def get_context_data(self, **kwargs):
        context = super(StudentProfileView, self).get_context_data(**kwargs)

        context['title'] = 'Student Profile'

        return context

# TODO
class StudentFlashcardView(StudentView, TemplateView):
    template_name = 'student/flashcards.html'

    def get_context_data(self, **kwargs):
        context = super(StudentFlashcardView, self).get_context_data(**kwargs)

        context['title'] = 'Student Flashcards'

        return context