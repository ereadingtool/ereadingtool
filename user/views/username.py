from auth.normal_auth import jwt_valid
import json

from django.http import HttpResponse, HttpRequest
from django.core.exceptions import ValidationError
from django.views.decorators.csrf import csrf_exempt

from user.models import ReaderUser

@csrf_exempt
@jwt_valid(403, "{'Error': 'Invalid JWT'}")
def username(request: HttpRequest) -> HttpResponse:
    errors = params = {}

    msg = None

    try:
        params = json.loads(request.body.decode('utf8'))
    except json.JSONDecodeError as e:
        return HttpResponse(json.dumps({'errors': {'json': str(e)}}), status=400)

    if 'username' not in params:
        return HttpResponse(json.dumps({'errors': {'username': 'This field is required.'}}), status=400)

    try:
        ReaderUser.username_validator(params['username'])

        if ReaderUser.objects.filter(username=params['username']).exists():
            raise ValidationError('This username is taken.')

        if len(params['username']) < 8:
            raise ValidationError('This username is too short.')

        if len(params['username']) > 32:
            raise ValidationError('This username is too long.')

        is_valid_username = True
        msg = 'This username is available.'
    except ValidationError as e:
        is_valid_username = False
        msg = str(e.message)

    return HttpResponse(json.dumps({'username': params['username'], 'valid': is_valid_username, 'msg': msg}),
                        status=200)
