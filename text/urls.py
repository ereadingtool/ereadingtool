from django.urls import path
from text.views.template import TextLoadElm, TextView, TextSearchView, TextSearchLoadElm

from text.views.api.text import TextAPIView
from text.views.api.tag import TextTagAPIView
from text.views.api.lock import TextLockAPIView
from text.views.api.translations import TextTranslationMatchAPIView
from text.views.api.text_word.word import TextWordAPIView, TextWordTranslationsAPIView
from text.views.api.text_word.group import TextWordGroupAPIView


urlpatterns = [
    path('api/text/word/compound/', TextWordGroupAPIView.as_view(), name='text-word-group-api'),

    path('api/text/word/<int:pk>/', TextWordAPIView.as_view(),
         name='text-word-api'),

    path('api/text/word/', TextWordAPIView.as_view(),
         name='text-word-api'),

    path('api/text/translations/match/', TextTranslationMatchAPIView.as_view(),
         name='text-translation-match-method'),

    path('api/text/word/<int:pk>/translation/<int:tr_pk>/', TextWordTranslationsAPIView.as_view(),
         name='text-word-translation-api'),

    path('api/text/word/<int:pk>/translation/', TextWordTranslationsAPIView.as_view(),
         name='text-word-translation-api'),

    path('api/text/<int:pk>/', TextAPIView.as_view(), name='text-item-api'),
    path('api/text/', TextAPIView.as_view(), name='text-api'),

    path('api/text/<int:pk>/tag/', TextTagAPIView.as_view(), name='text-tag-api'),
    path('api/text/<int:pk>/lock/', TextLockAPIView.as_view(), name='text-lock-api'),

    path('text/search/load_elm.js', TextSearchLoadElm.as_view(), name='text-search-load-elm'),
    path('text/search/', TextSearchView.as_view(), name='text-search'),

    path('text/<int:pk>/load_elm.js', TextLoadElm.as_view(), name='text-load-elm'),
    path('text/<int:pk>/', TextView.as_view(), name='text'),
]
