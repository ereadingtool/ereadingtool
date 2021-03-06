import pdfkit
from django.contrib.auth.mixins import LoginRequiredMixin
from django.core.files.base import ContentFile
from django.http import HttpResponse, HttpRequest, HttpResponseForbidden
from django.template import loader
from django.utils import timezone as dt
from django.views.generic import View

from user.student.models import Student


class StudentPerformancePDFView(LoginRequiredMixin, View):
    # returns permission denied HTTP message rather than redirect to login
    raise_exception = True

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not Student.objects.filter(pk=kwargs['pk']).exists():
            return HttpResponse(status=400)

        student = Student.objects.get(pk=kwargs['pk'])

        if student.user != self.request.user:
            return HttpResponseForbidden()

        today = dt.now()

        pdf_filename = f'my_ereader_performance_{today.day}_{today.month}_{today.year}.pdf'

        performance_report_html = loader.render_to_string('student_performance_report.html',
                                                          {'performance_report': student.performance.to_dict()})

        pdf_data = pdfkit.from_string(performance_report_html, False)

        pdf = ContentFile(pdf_data)

        resp = HttpResponse(pdf, 'application/pdf')

        resp['Content-Length'] = pdf.size
        resp['Content-Disposition'] = f'attachment; filename="{pdf_filename}"'

        return resp
