ELM_MAKE = /usr/local/bin/elm-make

.PHONY: admin
admin:
	for f in instructor_admin/ui/*.elm; do ${ELM_MAKE} $$f --warn --output=instructor_admin/static/admin/js/$$(basename -s .elm $$f).js; done;

.PHONY: quiz
quiz:
	for f in quiz/ui/*.elm; do ${ELM_MAKE} $$f --warn --output=quiz/static/quiz/js/$$(basename -s .elm $$f).js; done;

.PHONY: user
user:
	for f in user/ui/{instructor,student}/*.elm; do ${ELM_MAKE} $$f --warn --output=user/static/user/js/$$(basename -s .elm $$f).js; done;

.PHONY: all
all: admin quiz user
