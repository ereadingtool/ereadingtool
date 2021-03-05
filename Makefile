ELM_MAKE = /usr/local/bin/elm make

.PHONY: admin
admin:
	for f in instructor_admin/ui/*.elm; do ${ELM_MAKE} $$f --output=instructor_admin/static/admin/js/$$(basename -s .elm $$f | tr '[:upper:]' '[:lower:]').js; done;

.PHONY: text
text:
	for f in text/ui/*.elm; do ${ELM_MAKE} $$f --output=text/static/text/js/$$(basename -s .elm $$f | tr '[:upper:]' '[:lower:]').js; done;

.PHONY: user
user:
	for f in user/ui/Instructor/{Instructor_Login,Instructor_Profile,Instructor_Signup}.elm; do ${ELM_MAKE} $$f --output=user/static/user/js/$$(basename -s .elm $$f | tr '[:upper:]' '[:lower:]').js; done;
	for f in user/ui/Student/{Student_Login,Student_Profile,Student_Signup}.elm; do ${ELM_MAKE} $$f --output=user/static/user/js/$$(basename -s .elm $$f | tr '[:upper:]' '[:lower:]').js; done;
	for f in user/ui/ForgotPassword/*.elm; do ${ELM_MAKE} $$f --output=user/static/user/js/$$(basename -s .elm $$f | tr '[:upper:]' '[:lower:]').js; done;

.PHONY: flashcard
flashcard:
	for f in flashcards/ui/*.elm; do ${ELM_MAKE} $$f --output=flashcards/static/flashcards/js/$$(basename -s .elm $$f | tr '[:upper:]' '[:lower:]').js; done;

.PHONY: all
all: admin text user flashcard
