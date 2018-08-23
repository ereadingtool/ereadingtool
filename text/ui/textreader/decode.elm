module TextReader.Decode exposing (..)

import Json.Decode
import TextReader.Model exposing (..)

import TextReader.Section.Model exposing (Section)

import TextReader.Section.Decode
import TextReader.Text.Decode

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


command_resp_decoder : String -> Json.Decode.Decoder CmdResp
command_resp_decoder cmd_str =
  case cmd_str of
    "intro" -> let _ = Debug.log "server resp" "intro" in
      startDecoder

    "in_progress" -> let _ = Debug.log "server resp" "in_progress" in
      sectionDecoder InProgressResp

    "exception" ->
      Json.Decode.map ExceptionResp (Json.Decode.field "result" exceptionDecoder)

    "complete" -> let _ = Debug.log "server resp" "complete" in
      Json.Decode.map CompleteResp (Json.Decode.field "result" textScoresDecoder)

    _ ->
      Json.Decode.fail ("Command " ++ cmd_str ++ " not supported")


sectionDecoder : (Section -> CmdResp) -> Json.Decode.Decoder CmdResp
sectionDecoder cmd_resp =
  Json.Decode.map cmd_resp (Json.Decode.field "result" TextReader.Section.Decode.sectionDecoder)

startDecoder : Json.Decode.Decoder CmdResp
startDecoder =
  Json.Decode.map StartResp (Json.Decode.field "result" TextReader.Text.Decode.textDecoder)

exceptionDecoder : Json.Decode.Decoder Exception
exceptionDecoder =
  decode Exception
    |> required "code" (Json.Decode.string)
    |> required "error_msg" (Json.Decode.string)

textScoresDecoder : Json.Decode.Decoder TextScores
textScoresDecoder =
  decode TextScores
    |> required "num_of_sections" (Json.Decode.int)
    |> required "complete_sections" (Json.Decode.int)
    |> required "section_scores" (Json.Decode.int)
    |> required "possible_section_scores" (Json.Decode.int)

ws_resp_decoder : Json.Decode.Decoder CmdResp
ws_resp_decoder =
  Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen command_resp_decoder