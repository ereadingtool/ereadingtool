source ~/venvs/ereadingtool/bin/activate;

export YANDEX_TRANSLATION_API_KEY="trnsl.1.1.20190307T025430Z.2a73662f49c7ad7d.14dba0bff1b33d2d7391d0723abb46f5ad702251";
export YANDEX_DEFINITION_API_KEY="dict.1.1.20190308T070202Z.759b74874a3044c4.db8e83096fadf9634026fe92eff4b455c50a703f"

./manage.py shell -c "from user.models import ReaderUser; r=ReaderUser.objects.filter(email='user+test@test.com'); r.delete() if r else exit();";
