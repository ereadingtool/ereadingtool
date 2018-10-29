#!/usr/bin/env python
import asyncio

import os
import websocket
import django
import random
import string

import functools
import time

import concurrent.futures

import json

from typing import AnyStr, List, Dict, Callable

from django.urls import reverse

import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ereadingtool.settings')

django.setup()

from user.student.models import Student
from text.models import Text

# TODO(andrew): can build from django settings
hostname_and_port = '0.0.0.0:8000'

load_elm_unauthed_student_signup = reverse('load-elm-unauth-student-signup')
student_signup_page = reverse('student-signup')

student_signup_uri = reverse('api-student-signup')
student_login_uri = reverse('api-student-login')


StudentUsername = AnyStr
StudentPassword = AnyStr


test_text = Text.objects.all()[0]


def signup_as_student(session: requests.Session, csrftoken: AnyStr) -> (StudentUsername, StudentPassword):
    rand_username_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=5))

    username = f'tester+{rand_username_part}@email.com'
    passwd = ''.join(random.choices(string.ascii_uppercase + string.ascii_lowercase + string.digits, k=10))

    resp = session.post(f'http://{hostname_and_port}{student_signup_uri}', json={
        'email': username,
        'password': passwd,
        'confirm_password': passwd,
        'difficulty': 'intermediate_mid'
    }, headers={'X-CSRFToken': csrftoken})

    if not resp.ok:
        raise Exception('ERROR: ' + resp.content.decode('utf8'))

    return username, passwd


def student_login(session: requests.Session, csrftoken: AnyStr, student_username: AnyStr,
                  student_password: AnyStr) -> requests.Session:
    resp = session.post(f'http://{hostname_and_port}{student_login_uri}', json={
        'username': student_username,
        'password': student_password,
    }, headers={'X-CSRFToken': csrftoken})

    if not resp.ok:
        raise Exception('ERROR: ' + resp.content.decode('utf8'))
    else:
        return session


def answer_question(i: int, ws: websocket.WebSocketApp, question: Dict):
    time.sleep(random.randint(0, 1))

    answers = question['answers']

    rand_ans = question['answers'][random.randint(0, len(answers)-1)]

    ws.send(json.dumps({'command': 'answer', 'answer_id': rand_ans['id']}))

    print(f'student {i} answered question {question["id"]} with answer {rand_ans["id"]}')


def answered(question: Dict) -> bool:
    return any([answer['answered_correctly'] is not None for answer in question['answers']])


def all_answered(questions: List[Dict]) -> bool:
    return all([answered(question) for question in questions])


def answer_questions(i: int, ws: websocket.WebSocketApp, questions: List[Dict]):
    for question in questions:
        time.sleep(random.randint(0, 2))

        answer_question(i, ws, question)


def on_error(ws: websocket.WebSocketApp, error: AnyStr):
    print(f' ERR: {error}')


def on_close(ws: websocket.WebSocketApp):
    print('connection closed')


def on_open(i: int) -> Callable:
    def open_handler(ws: websocket.WebSocketApp):
        print(f'student {i} connected to text reading ws')

    return open_handler


def on_message(i: int) -> Callable:
    def msg_handler(ws: websocket.WebSocketApp, message: AnyStr):
        message = json.loads(message)

        print(f'student {i} received message: {message["command"]}')

        time.sleep(random.randint(0, 5))

        if 'command' in message and message['command'] == 'intro':
            time.sleep(random.randint(0, 5))

            ws.send(json.dumps({'command': 'next'}))
            print(f'student {i} hit next')

        if 'command' in message and message['command'] == 'in_progress':
            time.sleep(random.randint(0, 5))

            if not all_answered(message['result']['questions']):
                print(f'student {i} answering questions')

                answer_questions(i, ws, message['result']['questions'])
            else:
                print(f'student {i} done answering questions')

                ws.send(json.dumps({'command': 'next'}))
                print(f'student {i} hit next')

        if 'command' in message and message['command'] == 'complete':
            print(f'student {i} completed a text reading and quit.')
            print(f'student {i} results: {message["result"]}')
            ws.keep_running = False

        if 'command' in message and message['command'] == 'exception':
            print(f'student {i} got an exception: {message}')
            ws.keep_running = False

    return msg_handler


def student_text_read(session: requests.Session, i: int):
    headers = {
        'Cookie': f"csrftoken={session.cookies['csrftoken']}; sessionid={session.cookies['sessionid']};",
        'Host': hostname_and_port,
     }

    ws = websocket.WebSocketApp(f'ws://{hostname_and_port}/student/text_read/{test_text.pk}/',
                                header=headers,
                                on_open=on_open(i),
                                on_message=on_message(i),
                                on_error=on_error,
                                on_close=on_close)

    ws.run_forever(ping_interval=5)


def run_student(i: int):
    session = requests.Session()

    print(f'starting run of student {i}')

    time.sleep(random.randint(1, 3))

    # to retrieve the CSRF token
    resp = session.get(f'http://{hostname_and_port}{load_elm_unauthed_student_signup}')

    time.sleep(random.randint(1, 3))

    assert resp.ok

    csrftoken = session.cookies['csrftoken']

    assert csrftoken

    student_username, student_password = signup_as_student(session, csrftoken)

    print(f'student {i} signed up as {student_username}')

    session = student_login(session, csrftoken, student_username, student_password)

    assert 'sessionid' in session.cookies

    student_text_read(session, i)


async def main():
    loop = asyncio.get_event_loop()

    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as pool:
        futures = [loop.run_in_executor(pool, functools.partial(run_student, i)) for i in range(13)]

        await asyncio.gather(*futures)

if __name__ == '__main__':
    # websocket.enableTrace(True)

    loop = asyncio.get_event_loop()

    loop.run_until_complete(main())

    loop.close()

    print('cleaning up..')
    # cleanup
    Student.objects.filter(user__email__endswith='@email.com').delete()
