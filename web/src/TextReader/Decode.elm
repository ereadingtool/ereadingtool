module TextReader.Decode exposing (..)

import Json.Decode
import Json.Decode.Pipeline exposing (required)
import TextReader.Model exposing (..)
import TextReader.Section.Decode
import TextReader.Section.Model exposing (Section)
import TextReader.Text.Decode


commandRespDecoder : String -> Json.Decode.Decoder CmdResp
commandRespDecoder cmdStr =
    case cmdStr of
        "intro" ->
            startDecoder

        "in_progress" ->
            sectionDecoder InProgressResp

        "exception" ->
            Json.Decode.map ExceptionResp (Json.Decode.field "result" exceptionDecoder)

        "complete" ->
            Json.Decode.map CompleteResp (Json.Decode.field "result" textScoresDecoder)

        "add_flashcard_phrase" ->
            Json.Decode.map
                AddToFlashcardsResp
                (Json.Decode.field "result" TextReader.Section.Decode.textWordInstanceDecoder)

        "remove_flashcard_phrase" ->
            Json.Decode.map
                RemoveFromFlashcardsResp
                (Json.Decode.field "result" TextReader.Section.Decode.textWordInstanceDecoder)

        _ ->
            Json.Decode.fail ("Command " ++ cmdStr ++ " not supported")


sectionDecoder : (Section -> CmdResp) -> Json.Decode.Decoder CmdResp
sectionDecoder cmd_resp =
    Json.Decode.map cmd_resp (Json.Decode.field "result" TextReader.Section.Decode.sectionDecoder)


startDecoder : Json.Decode.Decoder CmdResp
startDecoder =
    Json.Decode.map StartResp (Json.Decode.field "result" TextReader.Text.Decode.textDecoder)


exceptionDecoder : Json.Decode.Decoder Exception
exceptionDecoder =
    Json.Decode.succeed Exception
        |> required "code" Json.Decode.string
        |> required "error_msg" Json.Decode.string


textScoresDecoder : Json.Decode.Decoder TextScores
textScoresDecoder =
    Json.Decode.succeed TextScores
        |> required "num_of_sections" Json.Decode.int
        |> required "complete_sections" Json.Decode.int
        |> required "section_scores" Json.Decode.int
        |> required "possible_section_scores" Json.Decode.int


wsRespDecoder : Json.Decode.Decoder CmdResp
wsRespDecoder =
    Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen commandRespDecoder
