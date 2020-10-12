module User.Student.Profile.Decode exposing
    (  studentConsentRespDecoder
       -- , studentProfileDecoder

    , usernameValidationDecoder
    )

import InstructorAdmin.Text.Translations exposing (Phrase)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Text.Translations.Decode as TextTranslationsDecode
import TextReader.Section.Decode
import TextReader.TextWord
import User.Student.Performance.Report exposing (PerformanceReport)
import User.Student.Profile as StudentProfile exposing (StudentProfile, StudentProfileParams)
import User.Student.Profile.Model as StudentProfileModel
import User.Student.Resource as StudentResource
import Utils exposing (stringTupleDecoder)


usernameValidationDecoder : Json.Decode.Decoder StudentProfileModel.UsernameUpdate
usernameValidationDecoder =
    Json.Decode.succeed StudentProfileModel.UsernameUpdate
        |> required "username" (Json.Decode.map (StudentResource.toStudentUsername >> Just) Json.Decode.string)
        |> required "valid" (Json.Decode.nullable Json.Decode.bool)
        |> required "msg" (Json.Decode.nullable Json.Decode.string)


textWordParamsDecoder : Json.Decode.Decoder TextReader.TextWord.TextWordParams
textWordParamsDecoder =
    Json.Decode.succeed TextReader.TextWord.TextWordParams
        |> required "id" Json.Decode.int
        |> required "instance" Json.Decode.int
        |> required "phrase" Json.Decode.string
        |> required "grammemes" (Json.Decode.nullable (Json.Decode.list stringTupleDecoder))
        |> required "translations" TextReader.Section.Decode.textWordTranslationsDecoder
        |> required "word"
            (Json.Decode.map2 (\a b -> ( a, b ))
                (Json.Decode.index 0 Json.Decode.string)
                (Json.Decode.index 1 (Json.Decode.nullable TextTranslationsDecode.textGroupDetailsDecoder))
            )


wordTextWordDecoder : Json.Decode.Decoder (Maybe (List ( Phrase, TextReader.TextWord.TextWordParams )))
wordTextWordDecoder =
    Json.Decode.nullable
        (Json.Decode.list
            (Json.Decode.map2 (\a b -> ( a, b ))
                (Json.Decode.index 0 Json.Decode.string)
                (Json.Decode.index 1 textWordParamsDecoder)
            )
        )



-- performanceReportDecoder : Json.Decode.Decoder PerformanceReport
-- performanceReportDecoder =
--     Json.Decode.succeed PerformanceReport
--         |> required "html" Json.Decode.string
--         |> required "pdf_link" Json.Decode.string


studentProfileURIParamsDecoder : Json.Decode.Decoder StudentProfile.StudentURIParams
studentProfileURIParamsDecoder =
    Json.Decode.succeed StudentProfile.StudentURIParams
        |> required "logout_uri" Json.Decode.string
        |> required "profile_uri" Json.Decode.string



-- studentProfileParamsDecoder : Json.Decode.Decoder StudentProfileParams
-- studentProfileParamsDecoder =
--     Json.Decode.succeed StudentProfileParams
--         |> required "id" (Json.Decode.nullable Json.Decode.int)
--         |> required "username" (Json.Decode.nullable Json.Decode.string)
--         |> required "email" Json.Decode.string
--         |> required "difficulty_preference" (Json.Decode.nullable stringTupleDecoder)
--         |> required "difficulties" (Json.Decode.list stringTupleDecoder)
--         |> required "uris" studentProfileURIParamsDecoder
--
-- studentProfileDecoder : Json.Decode.Decoder StudentProfile.StudentProfile
-- studentProfileDecoder =
--     Json.Decode.map StudentProfile.initProfile studentProfileParamsDecoder


studentConsentRespDecoder : Json.Decode.Decoder StudentProfileModel.StudentConsentResp
studentConsentRespDecoder =
    Json.Decode.map
        StudentProfileModel.StudentConsentResp
        (Json.Decode.field "consented" Json.Decode.bool)
