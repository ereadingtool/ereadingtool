module Flashcard.Decode exposing (..)

import Json.Decode
import Flashcard.Model exposing (..)

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


command_resp_decoder : String -> Json.Decode.Decoder CmdResp
command_resp_decoder cmd_str =
  case cmd_str of
    "init" ->
      startDecoder

    _ ->
      Json.Decode.fail ("Command " ++ cmd_str ++ " not supported")

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