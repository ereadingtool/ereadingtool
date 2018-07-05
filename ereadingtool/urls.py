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
from django.views.generic import RedirectView

from mixins.view import ElmLoadJsView, NoAuthElmLoadJsView, ElmLoadStudentSignUpView

urlpatterns = [
    path('load_elm.js', ElmLoadJsView.as_view(), name='load-elm'),
    path('load_elm_unauth.js', NoAuthElmLoadJsView.as_view(), name='load-elm-unauth'),

    path('load_elm_unauth_student.js', ElmLoadStudentSignUpView.as_view(), name='load-elm-unauth-student-signup'),

    path('', include('user.urls.instructor')),
    path('', include('user.urls.student')),

    path('', include('text.urls')),
    path('api/text/', include('text_old.urls')),
    path('api/question/', include('question.urls')),

    path('admin/', include('instructor_admin.urls')),

    path('django-admin/', admin.site.urls),
    path('', RedirectView.as_view(url=reverse_lazy('student-login')))
]
