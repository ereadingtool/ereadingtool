from django.template.loader import render_to_string
import pdfkit
import os
import time
import jwt
from urllib.parse import parse_qs
from django.core.files.base import ContentFile
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.template import loader
from django.utils import timezone as dt
from django.views.generic import View
from jwt.exceptions import InvalidTokenError

from user.student.models import Student

class StudentPerformancePDFView(View):

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).exists():
            return HttpResponse(status=400)

        jwt_user = jwt_validation(self.request.scope)

        # confirm the user_id from the URL is the same as the JWT's
        if jwt_user == None or jwt_user.pk != kwargs['pk']:
            return HttpResponse(render_to_string('error_page.html'))

        student = Student.objects.get(pk=kwargs['pk'])

        today = dt.now()

        pdf_filename = f'my_ereader_performance_{today.month}_{today.day}_{today.year}.pdf'

        performance_report_html = loader.render_to_string('student_performance_report.html',
                                                          {'performance_report': student.performance.to_dict(),
                                                           'timestamp': f'{today.month}/{today.day}/{today.year}',
                                                           'student': student.user.email
                                                          })

        pdf_data = pdfkit.from_string(performance_report_html, False)

        pdf = ContentFile(pdf_data)

        resp = HttpResponse(pdf, 'application/pdf')

        resp['Content-Length'] = pdf.size
        resp['Content-Disposition'] = f'attachment; filename="{pdf_filename}"'

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