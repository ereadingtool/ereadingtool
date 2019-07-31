module Config exposing (..)


text_translation_api_match_endpoint : String
text_translation_api_match_endpoint = "/api/text/translations/match/"

text_section_api_endpoint : String
text_section_api_endpoint = "/api/section/"

question_api_endpoint : String
question_api_endpoint = "/api/question/"

text_page : Int -> String
text_page text_id =
  "/text/" ++ toString text_id ++ "/"

answer_feedback_limit : Int
answer_feedback_limit = 2048
