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

from quiz.views import QuizView, QuizLoadElm
from user.views.mixin import ElmLoadJsView


urlpatterns = [
    path('load_elm.js', ElmLoadJsView.as_view(), name='load-elm'),

    path('', include('user.urls.instructor')),
    path('', include('user.urls.student')),

    path('api/text/', include('text.urls')),
    path('api/question/', include('question.urls')),

    path('admin/', include('instructor_admin.urls')),

    path('quiz/<int:pk>/load_elm.js', QuizLoadElm.as_view(), name="quiz-load-elm"),
    path('quiz/<int:pk>/', QuizView.as_view(), name="quiz"),

    path('django-admin/', admin.site.urls),
    path('', RedirectView.as_view(url=reverse_lazy('student-login')))
]
