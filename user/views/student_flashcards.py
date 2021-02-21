from django.http.request import HttpRequest
from django.http.response import HttpResponse
from django.template.loader import render_to_string
import pdfkit
import os
import time
import jwt
import csv as csv_module
import io
from jwt.exceptions import InvalidTokenError
from urllib.parse import parse_qs
from user.student.models import Student
from django.views.generic import View
from django.utils import timezone as dt
from django.template import loader
from django.core.files.base import ContentFile

class StudentFlashcardsPDFView(View):

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).exists():
            return HttpResponse(status=400)

        jwt_user = jwt_validation(self.request.scope)

        if jwt_user == None or jwt_user.pk != kwargs['pk']:
            return HttpResponse(render_to_string('error_page.html'))

        student = Student.objects.get(pk=kwargs['pk'])

        today = dt.now()

        pdf_filename = f'words_{today.day}_{today.month}_{today.year}.pdf'

        flashcards_report_html = loader.render_to_string('student_flashcards_report.html',
                                                         {'texts': student.flashcards_report.to_dict(),
                                                          'timestamp': f'{today.day}/{today.month}/{today.year}',
                                                          'student': student.user.email
                                                         })

        pdf_data = pdfkit.from_string(flashcards_report_html, False)

        pdf = ContentFile(pdf_data)

        resp = HttpResponse(pdf, 'text/pdf')

        resp['Content-Length'] = pdf.size
        resp['Content-Disposition'] = f'attachment; filename="{pdf_filename}"'

        return resp


class StudentFlashcardsCSVView(View):
    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).exists():
            return HttpResponse(status=400)

        jwt_user = jwt_validation(self.request.scope)

        if jwt_user == None or jwt_user.pk != kwargs['pk']:
            return HttpResponse(render_to_string('error_page.html'))

        student = Student.objects.get(pk=kwargs['pk'])

        today = dt.now()

        csv_filename = f'words_{today.day}_{today.month}_{today.year}.csv'

        flashcard_list = student.flashcards_csv.to_list()
        csv_data = io.StringIO(newline='')
        writer = csv_module.writer(csv_data, dialect=csv_module.unix_dialect)

        for fc in flashcard_list:
            writer.writerow(fc)
        csv_data = csv_data.getvalue()
        csv_data = csv_data.replace('"','') # getvalue() adds quotes around each row unnecessarily
        csv_data_size = len(bytes(csv_data, 'utf-8'))
        csv = ContentFile(csv_data)

        resp = HttpResponse(csv, content_type='text/csv')

        resp['Content-Length'] = csv_data_size
        resp['Content-Disposition'] = f'attachment; filename="{csv_filename}"'

        return resp


def jwt_validation(scope):
    """ Take JWT from query string to check the user against the db and validate its timestamp """
    if not scope['query_string']:
        return None
    else:
        secret_key = os.getenv('DJANGO_SECRET_KEY')
        try:
            qs = parse_qs(scope['query_string'])[b'token'][0]
            jwt_decoded = jwt.decode(qs, secret_key, algorithms=['HS256'])

            if jwt_decoded['exp'] <= time.time():
                # then their token has expired 
                raise InvalidTokenError

            if not Student.objects.filter(user_id=jwt_decoded['user_id']):
                # then there is no user in the QuerySet
                raise InvalidTokenError
            # force evaluation of the QuerySet. We already know it contains at least one element
            jwt_user = list(Student.objects.filter(user_id=jwt_decoded['user_id']))[0]

            return jwt_user

        except InvalidTokenError: 
            return None