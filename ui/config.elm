module Config exposing (..)


username_validation_api_endpoint : String
username_validation_api_endpoint = "/api/username/"

text_api_endpoint : String
text_api_endpoint = "/api/text/"

text_translation_api_endpoint : Int -> String
text_translation_api_endpoint id = "/api/text/translation/" ++ toString id ++ "/"

text_section_api_endpoint : String
text_section_api_endpoint = "/api/section/"

question_api_endpoint : String
question_api_endpoint = "/api/question/"

instructor_signup_api_endpoint : String
instructor_signup_api_endpoint = "/api/instructor/signup/"

instructor_login_api_endpoint : String
instructor_login_api_endpoint = "/api/instructor/login/"

instructor_logout_api_endpoint : String
instructor_logout_api_endpoint = "/api/instructor/logout/"

student_signup_api_endpoint : String
student_signup_api_endpoint = "/api/student/signup/"

student_login_api_endpoint : String
student_login_api_endpoint = "/api/student/login/"

student_logout_api_endpoint : String
student_logout_api_endpoint = "/api/student/logout/"

forgot_pass_endpoint : String
forgot_pass_endpoint = "/api/password/reset/"

reset_pass_endpoint : String
reset_pass_endpoint = "/api/password/reset/confirm/"

student_api_endpoint : String
student_api_endpoint = "/api/student/"

student_profile_page : String
student_profile_page = "/profile/student/"

instructor_profile_page : String
instructor_profile_page = "/profile/instructor/"

student_signup_page : String
student_signup_page = "/signup/student/"

instructor_signup_page : String
instructor_signup_page = "/signup/instructor/"

student_login_page : String
student_login_page = "/login/student/"

instructor_login_page : String
instructor_login_page = "/login/instructor/"

forgot_password_page : String
forgot_password_page = "/user/password_reset/"

text_page : Int -> String
text_page text_id =
  "/text/" ++ toString text_id ++ "/"

answer_feedback_limit : Int
answer_feedback_limit = 2048
