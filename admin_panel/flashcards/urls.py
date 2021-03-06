from django.urls import path

from flashcards.views import StudentFlashcardView, FlashcardsLoadElm

urlpatterns = [
    path('student/flashcards/', StudentFlashcardView.as_view(), name='flashcards'),
    path('flashcards/load_elm.js', FlashcardsLoadElm.as_view(content_type='application/javascript'),
         name='flashcard-load-elm'),
]
