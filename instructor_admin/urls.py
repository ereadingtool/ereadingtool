from django.urls import path
from instructor_admin.views import (TextAdminView, AdminCreateEditTextView, AdminCreateEditElmLoadView,
                                    TextDefinitionView, TextDefinitionElmLoadView)

urlpatterns = [
    path('texts/', TextAdminView.as_view(), name='admin-text-search'),

    # template loads "load_elm.js" from either /text/<int:pk>/ or /text/
    # e.g. /text/<int:pk>/load_elm.js or /text/load_elm.js
    # (see template create_edit_text.html)
    path('text/load_elm.js', AdminCreateEditElmLoadView.as_view(), name='text-create-load-elm'),
    path('text/', AdminCreateEditTextView.as_view(), name='text-create'),

    path('text/<int:pk>/definitions/load_elm.js', TextDefinitionElmLoadView.as_view(),
         name='text-definitions-load-elm'),
    path('text/<int:pk>/definitions/', TextDefinitionView.as_view(), name='text-definitions'),

    path('text/<int:pk>/load_elm.js', AdminCreateEditElmLoadView.as_view(), name='text-edit-load-elm'),
    path('text/<int:pk>/', AdminCreateEditTextView.as_view(), name='text-edit'),
]
