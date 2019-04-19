module Config exposing (..)


username_validation_api_endpoint : String
username_validation_api_endpoint = "/api/username/"

text_api_endpoint : String
text_api_endpoint = "/api/text/"

text_translation_api_match_endpoint : String
text_translation_api_match_endpoint = "/api/text/translations/match/"

text_section_api_endpoint : String
text_section_api_endpoint = "/api/section/"

question_api_endpoint : String
question_api_endpoint = "/api/question/"

instructor_logout_api_endpoint : String
instructor_logout_api_endpoint = "/api/instructor/logout/"

student_logout_api_endpoint : String
student_logout_api_endpoint = "/api/student/logout/"

student_api_endpoint : String
student_api_endpoint = "/api/student/"

student_profile_page : String
student_profile_page = "/profile/student/"

instructor_profile_page : String
instructor_profile_page = "/profile/instructor/"

instructor_invite_uri : String
instructor_invite_uri = "/api/instructor/invite/"

text_page : Int -> String
text_page text_id =
  "/text/" ++ toString text_id ++ "/"

answer_feedback_limit : Int
answer_feedback_limit = 2048
