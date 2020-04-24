import random
import string
import time
from typing import AnyStr

from django.test.testcases import TestCase
from django.urls import reverse
from selenium.webdriver.firefox.webdriver import WebDriver, Options


class TestStudent(TestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        options = Options()
        options.add_argument('--headless')

        cls.selenium = WebDriver(executable_path='/usr/local/bin/geckodriver', firefox_options=options)

        cls.site_root = 'http://0.0.0.0:8000'

    @classmethod
    def tearDownClass(cls):
        cls.selenium.quit()
        super().tearDownClass()

    @property
    def current_relative_url(self):
        return self.selenium.current_url.replace(self.site_root, '')

    def error_with_screenshot(self):
        rand_filename = f'/tmp/{"".join(random.choices(string.ascii_lowercase, k=4))}.png'

        self.selenium.get_screenshot_as_file(rand_filename)

        print(f'ERROR screenshot: {rand_filename}')

    def test_sign_up(self, username: AnyStr, password: AnyStr) -> (AnyStr, AnyStr):
        signup_url = reverse('student-signup')

        self.selenium.get(''.join([self.site_root, signup_url]))

        self.assertIn('Signup', self.selenium.title, 'Signup not in sign up page title')

        signup_inputs = self.selenium.find_elements_by_xpath('//div[@class="signup_box"]//input')

        signup_inputs[0].send_keys(username)

        signup_inputs[1].send_keys(password)
        signup_inputs[2].send_keys(password)

        signup_submit = self.selenium.find_element_by_class_name('signup_submit')

        self.selenium.implicitly_wait(10)

        signup_submit.click()

        time.sleep(1)

        redirected_to_login = reverse('student-login') == self.current_relative_url

        self.assertTrue(redirected_to_login, 'successfully redirected to login')

        return username, password

    def test_profile_page(self):
        username, password = self.test_sign_up(username='user+test@test.com', password='pass4!123bea')

        self.test_login(username, password)

    def test_login(self, username: AnyStr, password: AnyStr):
        login_page_inputs = self.selenium.find_elements_by_xpath('//div[@class="login_box"]//input')

        username_input = login_page_inputs[0]
        password_input = login_page_inputs[1]

        login_submit = self.selenium.find_element_by_class_name('login_submit')

        username_input.send_keys(username)
        password_input.send_keys(password)

        login_submit.click()

        time.sleep(1)

        self.assertEquals(self.current_relative_url, reverse('student-profile'))
