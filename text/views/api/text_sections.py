from django.urls import reverse_lazy
from django.views.generic import View
from ereadingtool.views import APIView


class TextSectionDefinitionAPIView(APIView):
    login_url = reverse_lazy('instructor-login')
    allowed_methods = ['get', 'put', 'post', 'delete']
