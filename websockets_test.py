#!/usr/bin/env python
import asyncio
import os
import websockets
import django
import random
import string

import json

from typing import AnyStr

from django.urls import reverse

import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ereadingtool.settings')

django.setup()

from user.student.models import Student

# TODO(andrew): can build from django settings
hostname_and_port = '0.0.0.0:8000'

load_elm_unauthed_student_signup = reverse('load-elm-unauth-student-signup')
student_signup_page = reverse('student-signup')

student_signup_uri = reverse('api-student-signup')
student_login_uri = reverse('api-student-login')


StudentUsername = AnyStr
StudentPassword = AnyStr


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


async def student_text_read(session: requests.Session):
    ws = await websockets.connect(f'ws://{hostname_and_port}/student/text_read/1/', extra_headers={
        'Cookie': f"csrftoken={session.cookies['csrftoken']}; sessionid={session.cookies['sessionid']};",
        'Host': hostname_and_port,
        'Origin': f'http://{hostname_and_port}',
      })

    await ws.send('connect')

    resp = await ws.recv()

    text_intro = json.loads(resp)

    assert text_intro

    asyncio.sleep(random.randint(1, 3))

    await ws.send('connect')

    resp = await ws.recv()

    text_section_one = json.loads(resp)

    assert text_section_one

    await ws.close()


async def run_student(i: int):
    session = requests.Session()

    print(f'Starting run of student {i}')

    asyncio.sleep(random.randint(1, 3))

    # to retrieve the CSRF token
    resp = session.get(f'http://{hostname_and_port}{load_elm_unauthed_student_signup}')

    asyncio.sleep(random.randint(1, 3))

    assert resp.ok

    csrftoken = session.cookies['csrftoken']

    assert csrftoken

    student_username, student_password = signup_as_student(session, csrftoken)

    print(f'Student {i} signed up as {student_username}')

    session = student_login(session, csrftoken, student_username, student_password)

    assert 'sessionid' in session.cookies

    await student_text_read(session)


def main():
    loop = asyncio.get_event_loop()

    coros = [run_student(i) for i in range(1, 2)]

    loop.run_until_complete(asyncio.gather(*coros))

    loop.close()

    # cleanup
    Student.objects.filter(user__email__endswith='@email.com').delete()


if __name__ == '__main__':
    main()
