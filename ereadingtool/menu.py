from typing import AnyStr, List

from django.urls import reverse


class MenuItem(object):
    def __init__(self, url: AnyStr, link_text: AnyStr, selected: bool = False, *args, **kwargs):
        self.url = url
        self.link_text = link_text
        self.selected = selected

    def to_dict(self):
        return {
            'link': self.url,
            'link_text': self.link_text,
            'selected': self.selected
        }


class MenuItems(object):
    def __init__(self, items: List[MenuItem], *args, **kwargs):
        self.menu_items = items

    def to_dict(self):
        return [item.to_dict() for item in self.menu_items]


def student_menu_items():
    return MenuItems(items=[
        MenuItem(url=reverse('text-search'), link_text='Text Search'),
        MenuItem(url=reverse('flashcards'), link_text='Flashcards'),
    ])
