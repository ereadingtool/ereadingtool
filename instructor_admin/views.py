import json
from typing import Dict

from csp.decorators import csp_exempt

from django.middleware.csrf import get_token
from django.urls import reverse
from django.http import Http404
from django.http import HttpResponse, HttpRequest
from django.views.generic import TemplateView

from mixins.view import ElmLoadJsView
from text.models import Text
from question.models import Answer

from user.views.instructor import InstructorView

from ereadingtool.menu import MenuItems, instructor_create_a_text_menu_item


class AdminView(InstructorView, TemplateView):
    pass


class TextAdminView(AdminView):
    model = Text
    template_name = 'instructor_admin/admin.html'


class TextAdminElmLoadView(ElmLoadJsView):
    def get_instructor_menu_items(self) -> MenuItems:
        instructor_menu_items = super(TextAdminElmLoadView, self).get_instructor_menu_items()

        instructor_menu_items.append(instructor_create_a_text_menu_item())

        instructor_menu_items.select('admin-text-search')

        return instructor_menu_items

    def get_context_data(self, **kwargs) -> Dict:
        context_data = super(TextAdminElmLoadView, self).get_context_data()

        context_data['elm']['text_api_endpoint_url'] = {
            'quote': True,
            'safe': True,
            'value': reverse('text-api')
        }

        return context_data


class TextDefinitionElmLoadView(ElmLoadJsView):
    def get_context_data(self, **kwargs) -> Dict:
        context = super(TextDefinitionElmLoadView, self).get_context_data(**kwargs)

        if 'pk' in context:
            try:
                text = Text.objects.get(pk=context['pk'])
                words, word_freqs = text.definitions

                context['elm']['words'] = {
                    'quote': False,
                    'safe': True,
                    'value': json.dumps(list(words.items()))
                }

                context['elm']['word_frequencies'] = {
                    'quote': False,
                    'safe': True,
                    'value': json.dumps(list(word_freqs.items()))
                }
            except Text.DoesNotExist:
                pass

        return context


class TextDefinitionView(AdminView):
    model = Text
    template_name = 'instructor_admin/text_definitions.html'

    def get(self, request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(TextDefinitionView, self).get(request, *args, **kwargs)


class AdminCreateEditTextView(AdminView):
    model = Text

    fields = ('source', 'difficulty', 'body',)
    template_name = 'instructor_admin/create_edit_text.html'

    def get(self, request, *args, **kwargs) -> HttpResponse:
        if 'pk' in kwargs and not self.model.objects.filter(pk=kwargs['pk']):
            raise Http404('text does not exist')

        return super(AdminCreateEditTextView, self).get(request, *args, **kwargs)

    # GA's nonce CSP policy conflicts with previously used unsafe-inline.
    # Attempts at using nonce with CkEditor failed so making this csp_exempt for now
    @csp_exempt
    def dispatch(self, request, *args, **kwargs):
        return super(AdminCreateEditTextView, self).dispatch(request, *args, **kwargs)


class AdminCreateEditElmLoadView(ElmLoadJsView):
    template_name = 'instructor_admin/load_elm.html'

    def get_context_data(self, **kwargs):
        context = super(AdminCreateEditElmLoadView, self).get_context_data(**kwargs)
        text = None

        if 'pk' in context:
            try:
                text = Text.objects.get(pk=context['pk'])
            except Text.DoesNotExist:
                pass

        context['elm']['text'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(text.to_dict() if text else None)
        }

        context['elm']['tags'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps([tag.name for tag in Text.tag_choices()])
        }

        context['elm']['translation_flags'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps({
                'csrftoken': get_token(self.request),
                'add_as_text_word_endpoint_url': reverse('text-word-api'),
                'merge_textword_endpoint_url': reverse('text-word-group-api'),
                'text_translation_match_endpoint': reverse('text-translation-match-method')
            })
        }

        context['elm']['text_endpoint_url'] = {
            'quote': False,
            'safe': True,
            'value': json.dumps(reverse('text-api'))
        }

        context['elm']['answer_feedback_limit'] = {
            'quote': False,
            'safe': True,
            'value': Answer._meta.get_field('feedback').max_length
        }

        return context
