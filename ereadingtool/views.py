from typing import Dict

from django.utils.translation import gettext as _
from django.views.generic import View, TemplateView
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator


class APIView(View):
    @method_decorator(csrf_exempt)
    def dispatch(self, request, *args, **kwargs):
        return super(APIView, self).dispatch(request, *args, **kwargs)


class AcknowledgementView(TemplateView):
    template_name = 'acknowledgements.html'


class AboutView(TemplateView):
    template_name = 'about.html'

    def get_context_data(self, **kwargs) -> Dict:
        context = super(AboutView, self).get_context_data(**kwargs)

        context.update({
            'alt_txt_1': _("Screenshot of login page"),
            'alt_txt_2': _("Screenshot of profile page with difficulty level options"),
            'alt_txt_3': _("Screenshot of student performance table"),
            'alt_txt_4': _("Screenshot of search filter for text difficulty level"),
            'alt_txt_5': _("Screenshot of search filter for text topics"),
            'alt_txt_6': _("Screenshot of search filter for text read status"),
            'alt_txt_7': _("Screenshot of text pre-reading screen, with a brief description of the text and a Start "
                           "button"),
            'alt_txt_8': _("Screenshot of one section of a text"),
            'alt_txt_9': _("Screenshot of a text with a word glossed"),
            'alt_txt_10': _("Screenshot of a multiple-choice comprehension question"),

            'alt_txt_11_left': _("Screenshot of a text comprehension question answered correctly with feedback"),
            'alt_txt_11_right': _("Screenshot of a text comprehension question answered incorrectly with feedback"),

            'alt_txt_12': _("Screenshot of post-reading page with number of questions answered correctly, "
                            "a message directing students to the Search Texts page, and a link to a reading related "
                            "to the text"),
            'alt_txt_13': _("Screenshot of the two mode options for flashcards, which are “Review Only” mode and "
                            "“Review and Answer” mode"),

            'alt_txt_14_left': _("Screenshot of the front of a flashcard in “Review only” mode, with the Russian word "
                                 "and its context"),
            'alt_txt_14_right': _("Screenshot of the back of a flashcard in “Review only” mode, with the English "
                                  "translation of the Russian word, and the word’s context"),
            'alt_txt_15_left': _("Screenshot of the front of a flashcard in “Review and Answer” mode, with the Russian "
                                 "word, the word’s context, and a box where students type the answer"),
            'alt_txt_15_right': _("Screenshot of the back of a flashcard in “Review and Answer” mode, with the English "
                                  "translation of the Russian word, the word’s context, and six options from 0 to 5 "
                                  "(0 being the most difficult, 5 being the easiest) so that students can judge how "
                                  "difficult they found the word")
        })

        return context
