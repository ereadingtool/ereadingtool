from typing import AnyStr, List

from django.urls import reverse

from collections import OrderedDict


class MenuItem(object):
    def __init__(self, url_name: AnyStr, link_text: AnyStr, selected: bool = False, *args, **kwargs):
        self.url_name = url_name
        self.link_text = link_text
        self.selected = selected

        self.url = reverse(self.url_name)

    def select(self):
        self.selected = True

    def to_dict(self):
        return {
            'link': self.url,
            'link_text': self.link_text,
            'selected': self.selected
        }


class MenuItems(object):
    def __init__(self, items: List[MenuItem], *args, **kwargs):
        self.menu_items = OrderedDict({item.url_name: item for item in items})

    def select(self, url_name: AnyStr):
        try:
            self.menu_items[url_name].select()
        except KeyError:
            pass

    def to_dict(self):
        return [item.to_dict() for item in self.menu_items.values()]


def find_a_text_to_read_menu_item() -> MenuItem:
    return MenuItem(url_name='text-search', link_text='Find a text to read')


def practice_flashcards_menu_item() -> MenuItem:
    return MenuItem(url_name='flashcards', link_text='Practice Flashcards')


def instructor_text_search_menu_item() -> MenuItem:
    return MenuItem(url_name='admin-text-search', link_text='Find a text to edit')


def student_menu_items() -> MenuItems:
    return MenuItems(items=[
        find_a_text_to_read_menu_item(),
        practice_flashcards_menu_item(),
    ])


def instructor_menu_items():
    return MenuItems(items=[
        instructor_text_search_menu_item(),
        find_a_text_to_read_menu_item(),
    ])
