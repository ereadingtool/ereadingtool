import time

from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

from django.urls import reverse

from ereadingtool.test.user import TestUser


class EreaderSeleniumTests(TestUser, StaticLiveServerTestCase):
    page_load_timeout = 2
    webdriver = None

    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        options = webdriver.FirefoxOptions()
        options.add_argument("--headless")

        cls.webdriver = webdriver.Firefox(firefox_options=options)
        cls.webdriver.implicitly_wait(10)

    @classmethod
    def tearDownClass(cls):
        cls.webdriver.quit()
        super().tearDownClass()

    def test_urls(self):
        test_username = 'test@tester.com'
        test_password = 'test'

        (user, _) = self.new_user(test_password, test_username)

        instructor = self.new_instructor_with_user(user)

        instructor_login_url = reverse('instructor-login')
        instructor_profile_url = reverse('instructor-profile')

        self.webdriver.get(f'{self.live_server_url}{instructor_login_url}')

        username_input = self.webdriver.find_element_by_id('username')

        username_input.send_keys(test_username)

        password_input = self.webdriver.find_element_by_id('password')

        password_input.send_keys(test_password)

        self.webdriver.get_screenshot_as_file('test.png')

        login_submit = self.webdriver.find_element_by_xpath('//div[@class="button cursor"]/div[@id="login_submit"]/..')

        login_submit.click()

        self.webdriver.implicitly_wait(5)

        self.webdriver.get(f'{self.live_server_url}{instructor_profile_url}')

        print(self.webdriver.page_source)

        self.assertEquals('Steps To Advanced Reading - Instructor Profile', self.webdriver.title, 'not logged in')
