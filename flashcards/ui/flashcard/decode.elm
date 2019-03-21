module Flashcard.Decode exposing (..)

import Json.Decode
import Flashcard.Model exposing (..)

import Flashcard.Mode

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


command_resp_decoder : String -> Json.Decode.Decoder CmdResp
command_resp_decoder cmd_str =
  case cmd_str of
    "init" ->
      startDecoder

    "mode_choice" ->
      modeChoicesDecoder

    _ ->
      Json.Decode.fail ("Command " ++ cmd_str ++ " not supported")

modeChoicesDecoder : Json.Decode.Decoder CmdResp
modeChoicesDecoder =
  Json.Decode.map ChooseModeChoice (Json.Decode.field "result" modeChoicesDescDecoder)

modeDecoder : Json.Decode.Decoder Flashcard.Mode.ModeChoice
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

startDecoder : Json.Decode.Decoder CmdResp
startDecoder =
  Json.Decode.map InitResp (Json.Decode.field "result" Json.Decode.string)

exceptionDecoder : Json.Decode.Decoder Exception
exceptionDecoder =
  decode Exception
    |> required "code" (Json.Decode.string)
    |> required "error_msg" (Json.Decode.string)

ws_resp_decoder : Json.Decode.Decoder CmdResp
ws_resp_decoder =
  Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen command_resp_decoder