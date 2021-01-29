"""
Django settings for ereadingtool project.

Generated by 'django-admin startproject' using Django 2.0.3.

For more information on this file, see
https://docs.djangoproject.com/en/2.0/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/2.0/ref/settings/
"""
import datetime
import os

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            # When the container spawns it's aliased to "redis" see docker insepct <redis_container> output
            'hosts': [(os.getenv('REDIS_ENDPOINT'), 6379)], 
        },
    },
}

# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/2.0/howto/deployment/checklist/

ADMINS = [('Andrew', 'als2@pdx.edu'), ('EReader', 'ereader@pdx.edu')]

# Prevents CommondMiddleware from `APPEND_SLASH` (defaulted to `True`)
# adding a forward slash to all URLs sent to the backend (by way of 301)
APPEND_SLASH = False

YANDEX_TRANSLATION_API_KEY = os.getenv('YANDEX_TRANSLATION_API_KEY')
YANDEX_DEFINITION_API_KEY = os.getenv('YANDEX_DEFINITION_API_KEY')

# days
INVITATION_EXPIRY = 7

JWT_EXPIRATION_DELTA = datetime.timedelta(seconds=86400)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'filters': {
        'require_debug_false': {
                '()': 'django.utils.log.RequireDebugFalse',
        },
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue'
        }
    },
    'handlers': {
        'console_info': {
            'level': 'INFO',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
        'console_debug': {
            'level': 'DEBUG',
            'filters': [],
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
        'mail_admins': {
            'level': 'ERROR',
            'class': 'django.utils.log.AdminEmailHandler',
            'include_html': True,
            'filters': ['require_debug_true']
        },
        'mail_admins_info': {
            'level': 'INFO',
            'class': 'django.utils.log.AdminEmailHandler',
            'include_html': True,
            'filters': []
        }
    },
    'loggers': {
        'django': {
            'handlers': ['console_info', 'mail_admins'],
            'level': 'INFO',
            'propagate': False,
        },
        'django.consumers': {
            'handlers': ['console_debug', 'mail_admins_info'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

DEBUG = True
DEV = False

ALLOWED_HOSTS = ['0.0.0.0',
                 'localhost',
                 '142.93.20.73',
                 'stepstoadvancedreading.org',
                 'steps2advancedreading.org',
                 'steps2ar.org',
<<<<<<< HEAD
                 'api.steps2ar.org',
                 'admin.steps2ar.org',
                 'api.steps2advancedreading.org',
                 'admin.steps2advancedreading.org',
]
=======
                 'api.steps2ar.org'
                 , '*'
                 ]
>>>>>>> 9477b32b... Partially complete flashcards

CSP_DEFAULT_SRC = ("'self'",)
CSP_SCRIPT_SRC = ("'self'",)
CSP_CONNECT_SRC = ("'self'",)
CSP_IMG_SRC = ("'self'", "https://www.google-analytics.com",)
CSP_STYLE_SRC = ("'self'",)

CSP_INCLUDE_NONCE_IN = ['script-src']

INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

# third-party apps
INSTALLED_APPS += [
    'channels',
    'corsheaders',
]

# project apps
INSTALLED_APPS += [
    'question',
    'user',
    'instructor_admin',
    'text',
    'text_reading',
    'tag',
    'report',
    'flashcards',
    'invite',
    'first_time_correct',
    'django.contrib.admin',
]


AUTH_USER_MODEL = 'user.ReaderUser'

EMAIL_BACKEND = 'sendgrid_backend.SendgridBackend'

SENDGRID_API_KEY = os.getenv('SENDGRID_API_KEY')
# You must set also DEBUG=False for sandbox_mode to be enabled
SENDGRID_SANDBOX_MODE_IN_DEBUG = False

ASGI_APPLICATION = 'ereadingtool.routing.application'
# CHANNEL_LAYERS = {}

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'jwt_auth.middleware.JWTAuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'csp.middleware.CSPMiddleware',
]

ROOT_URLCONF = 'ereadingtool.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            os.path.join(BASE_DIR, 'ereadingtool/templates'),
            os.path.join(BASE_DIR, 'user/templates'),
            os.path.join(BASE_DIR, 'question/templates'),
            os.path.join(BASE_DIR, 'instructor_admin/templates'),
            os.path.join(BASE_DIR, 'text/templates'),
            os.path.join(BASE_DIR, 'report/templates'),
            os.path.join(BASE_DIR, 'flashcards/templates')
        ]
        ,
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ereadingtool.wsgi.application'


# Database
# https://docs.djangoproject.com/en/2.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
        'TEST_NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}


# Password validation
# https://docs.djangoproject.com/en/2.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

CORS_ORIGIN_WHITELIST = [
    'http://localhost:1234'
]


# Internationalization
# https://docs.djangoproject.com/en/2.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/2.0/howto/static-files/

STATIC_URL = '/static/'

STATIC_ROOT = 'static/'

STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'ereadingtool/static')
]

try:
    from local_settings import *
except ImportError:
    pass
