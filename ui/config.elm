module Config exposing (..)

text_api_endpoint : String
text_api_endpoint = "/api/text/"

question_api_endpoint : String
question_api_endpoint = "/api/question/"

instructor_signup_api_endpoint : String
instructor_signup_api_endpoint = "/api/instructor/signup/"

instructor_login_api_endpoint : String
instructor_login_api_endpoint = "/api/instructor/login/"

student_signup_api_endpoint : String
student_signup_api_endpoint = "/api/student/signup/"

student_login_api_endpoint : String
student_login_api_endpoint = "/api/student/login/"

student_api_endpoint : String
student_api_endpoint = "/api/student/"

text_intro_limit : Int
text_intro_limit = 2048

answer_feedback_limit : Int
answer_feedback_limit = 2048