module Flashcard.Decode exposing (..)

import Flashcard.Mode exposing (Mode)
import Flashcard.Model exposing (..)
import Json.Decode
import Json.Decode.Pipeline exposing (required)


command_resp_decoder : String -> Json.Decode.Decoder CmdResp
command_resp_decoder cmd_str =
    case cmd_str of
        "init" ->
            startDecoder

        "mode_choice" ->
            modeChoicesDecoder

        "review_card" ->
            reviewCardDecoder

        "review_and_answer_card" ->
            reviewCardAndAnswerDecoder

        "correctly_answered_card" ->
            reviewedCardAndAnsweredCorrectlyDecoder

        "incorrectly_answered_card" ->
            reviewedCardAndAnsweredIncorrectlyDecoder

        "rated_your_answer_for_card" ->
            ratedQualityDecoder

        "reviewed_card" ->
            reviewedCardDecoder

        "exception" ->
            Json.Decode.map ExceptionResp (Json.Decode.field "result" exceptionDecoder)

        "finished_review" ->
            Json.Decode.succeed FinishedReviewResp

        _ ->
            Json.Decode.fail ("Command " ++ cmd_str ++ " not supported")


reviewedCardDecoder : Json.Decode.Decoder CmdResp
reviewedCardDecoder =
    Json.Decode.map ReviewedCardResp (Json.Decode.field "result" flashcardDecoder)


flashcardDecoder : Json.Decode.Decoder Flashcard
flashcardDecoder =
    Json.Decode.map3 Flashcard.Model.newFlashcard
        (Json.Decode.field "phrase" Json.Decode.string)
        (Json.Decode.field "example" Json.Decode.string)
        (Json.Decode.field "translation" (Json.Decode.nullable Json.Decode.string))


reviewCardDecoder : Json.Decode.Decoder CmdResp
reviewCardDecoder =
    Json.Decode.map ReviewCardResp (Json.Decode.field "result" flashcardDecoder)


reviewCardAndAnswerDecoder : Json.Decode.Decoder CmdResp
reviewCardAndAnswerDecoder =
    Json.Decode.map ReviewCardAndAnswerResp (Json.Decode.field "result" flashcardDecoder)


reviewedCardAndAnsweredCorrectlyDecoder : Json.Decode.Decoder CmdResp
reviewedCardAndAnsweredCorrectlyDecoder =
    Json.Decode.map ReviewedCardAndAnsweredCorrectlyResp (Json.Decode.field "result" flashcardDecoder)


reviewedCardAndAnsweredIncorrectlyDecoder : Json.Decode.Decoder CmdResp
reviewedCardAndAnsweredIncorrectlyDecoder =
    Json.Decode.map ReviewedCardAndAnsweredIncorrectlyResp (Json.Decode.field "result" flashcardDecoder)


ratedQualityDecoder : Json.Decode.Decoder CmdResp
ratedQualityDecoder =
    Json.Decode.map RatedCardResp (Json.Decode.field "result" flashcardDecoder)


modeChoicesDecoder : Json.Decode.Decoder CmdResp
modeChoicesDecoder =
    Json.Decode.map ChooseModeChoiceResp (Json.Decode.field "result" modeChoicesDescDecoder)


modeDecoder : Json.Decode.Decoder Mode
modeDecoder =
    Json.Decode.map Flashcard.Mode.modeFromString Json.Decode.string


modeChoiceDescDecoder : Json.Decode.Decoder Flashcard.Mode.ModeChoiceDesc
modeChoiceDescDecoder =
    Json.Decode.map3
        Flashcard.Mode.ModeChoiceDesc
        (Json.Decode.field "mode" modeDecoder)
        (Json.Decode.field "desc" Json.Decode.string)
        (Json.Decode.field "selected" Json.Decode.bool)


modeChoicesDescDecoder : Json.Decode.Decoder (List Flashcard.Mode.ModeChoiceDesc)
modeChoicesDescDecoder =
    Json.Decode.list modeChoiceDescDecoder


initRespDecoder : Json.Decode.Decoder InitRespRec
initRespDecoder =
    Json.Decode.succeed InitRespRec
        |> required "flashcards" (Json.Decode.list Json.Decode.string)


startDecoder : Json.Decode.Decoder CmdResp
startDecoder =
    Json.Decode.map InitResp (Json.Decode.field "result" initRespDecoder)


exceptionDecoder : Json.Decode.Decoder Exception
exceptionDecoder =
    Json.Decode.succeed Exception
        |> required "code" Json.Decode.string
        |> required "error_msg" Json.Decode.string


ws_resp_decoder : Json.Decode.Decoder ( Maybe Mode, CmdResp )
ws_resp_decoder =
    Json.Decode.map2 (\a b -> ( a, b ))
        (Json.Decode.field "mode" (Json.Decode.nullable modeDecoder))
        (Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen command_resp_decoder)
