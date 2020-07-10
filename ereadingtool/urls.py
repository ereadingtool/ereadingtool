"""ereadingtool URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/2.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include, reverse_lazy
from django.views.generic import RedirectView, TemplateView

from jwt_auth import views as jwt_auth_views

from mixins.view import (ElmLoadJsView, NoAuthElmLoadJsView)

from ereadingtool.views import AcknowledgementView, AboutView

from user.views.username import username

urlpatterns = [
    path('load_elm.js', ElmLoadJsView.as_view(), name='load-elm'),
    path('load_elm_unauth.js', NoAuthElmLoadJsView.as_view(), name='load-elm-unauth'),

    path("token-auth/", jwt_auth_views.jwt_token, name='jwt-token-auth'),
    path("token-refresh/", jwt_auth_views.refresh_jwt_token, name='jwt-token-refresh'),

    path('acknowledgements/', AcknowledgementView.as_view(), name='acknowledgements'),
    path('about/', AboutView.as_view(), name='about'),

    path('', include('user.urls.instructor')),
    path('', include('user.urls.student')),
    path('', include('user.urls.forgot_pass')),

    path('', include('flashcards.urls')),
    path('', include('text.urls')),

    path('api/username/', username, name='username-api'),
    path('api/question/', include('question.urls')),

    path('admin/', include('instructor_admin.urls')),

    path('django-admin/', admin.site.urls),

    path('', RedirectView.as_view(url=reverse_lazy('student-login'))),
    path('error', TemplateView.as_view(template_name='error_page.html'), name='error-page'),
]
