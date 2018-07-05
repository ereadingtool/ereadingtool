from django.urls import path
from text.views.template import TextLoadElm, TextView

from text.views.api.text import TextAPIView
from text.views.api.tag import TextTagAPIView
from text.views.api.lock import TextLockAPIView

urlpatterns = [
    path('api/text/<int:pk>/', TextAPIView.as_view(), name='text-api'),
    path('api/text/', TextAPIView.as_view(), name='text-api'),

    path('api/text/<int:pk>/tag/', TextTagAPIView.as_view(), name='text-tag-api'),
    path('api/text/<int:pk>/lock/', TextLockAPIView.as_view(), name='text-lock-api'),

    path('text/<int:pk>/load_elm.js', TextLoadElm.as_view(), name='text-load-elm'),
    path('text/<int:pk>/', TextView.as_view(), name='text'),
]
