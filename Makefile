ELM_MAKE = /usr/local/bin/elm-make

.PHONY: admin
admin:
	for f in instructor_admin/ui/*.elm; do ${ELM_MAKE} $$f --warn --output=instructor_admin/static/admin/js/$$(basename -s .elm $$f).js; done;

.PHONY: text
text:
	for f in text/ui/*.elm; do ${ELM_MAKE} $$f --warn --output=text/static/text/js/$$(basename -s .elm $$f).js; done;

.PHONY: user
user:
	for f in user/ui/{instructor,student,forgot_password}/*.elm; do ${ELM_MAKE} $$f --warn --output=user/static/user/js/$$(basename -s .elm $$f).js; done;

.PHONY: flashcard
flashcard:
	for f in flashcards/ui/*.elm; do ${ELM_MAKE} $$f --warn --output=flashcards/static/flashcards/js/$$(basename -s .elm $$f).js; done;

.PHONY: all
all: admin text user flashcard
