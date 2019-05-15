from django.views.generic import TemplateView


class AcknowledgementView(TemplateView):
    template_name = 'acknowledgements.html'


class AboutView(TemplateView):
    template_name = 'about.html'
