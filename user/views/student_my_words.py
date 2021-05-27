from django.template.loader import render_to_string
from user.views.student_flashcards import jwt_validation
from django.http.request import HttpRequest
from django.http.response import HttpResponse
from django.views.generic import View
from user.student.models import Student
from django.template.loader import render_to_string
from django.template import loader


class StudentFlashcardsHTMLView(View):
    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).exists():
            return HttpResponse(status=400)
        
        jwt_user = jwt_validation(self.request.scope)

        # if jwt_user == None or jwt_user.pk != kwargs['pk']:
        #     return HttpResponse(render_to_string('error_page.html'))

        student = Student.objects.get(pk=kwargs['pk'])

        flashcards_report_html = loader.render_to_string('student_my_words.html',
                                                         {'words': student.flashcards_html.to_list()})


        return HttpResponse(flashcards_report_html)