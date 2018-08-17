module TextReader.Decode exposing (..)

import Array exposing (Array)

import Json.Decode
import TextReader.Model exposing (..)

import TextReader.Answer exposing (Answer)
import TextReader.Question exposing (Question)

import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)
import Json.Decode.Extra exposing (date)


startDecoder : Json.Decode.Decoder CmdResp
startDecoder =
  Json.Decode.map StartResp (Json.Decode.field "result" Json.Decode.bool)


answerDecoder : Json.Decode.Decoder Answer
answerDecoder =
  decode Answer
    |> required "id" (Json.Decode.int)
    |> required "question_id" (Json.Decode.int)
    |> required "text" Json.Decode.string
    |> required "order" Json.Decode.int
    |> required "feedback" Json.Decode.string

answersDecoder : Json.Decode.Decoder (Array Answer)
answersDecoder = Json.Decode.array answerDecoder

questionDecoder : Json.Decode.Decoder Question
questionDecoder =
  decode Question
    |> required "id" (Json.Decode.int)
    |> required "text_section_id" (Json.Decode.int)
    |> required "created_dt" (Json.Decode.nullable date)
    |> required "modified_dt" (Json.Decode.nullable date)
    |> required "body" Json.Decode.string
    |> required "order" Json.Decode.int
    |> required "answers" answersDecoder
    |> required "question_type" Json.Decode.string

questionsDecoder : Json.Decode.Decoder (Array Question)
questionsDecoder = Json.Decode.array questionDecoder


textSectionDecoder : Json.Decode.Decoder TextSection
textSectionDecoder =
  decode TextSection
    |> required "order" Json.Decode.int
    |> required "body" Json.Decode.string
    |> required "question_count" Json.Decode.int
    |> required "questions" questionsDecoder

textSectionsDecoder : Json.Decode.Decoder (List TextSection)
textSectionsDecoder = Json.Decode.list textSectionDecoder

textDecoder : Json.Decode.Decoder Text
textDecoder =
  decode Text
    |> required "id" (Json.Decode.int)
    |> required "title" (Json.Decode.string)
    |> required "introduction" (Json.Decode.string)
    |> required "author" (Json.Decode.string)
    |> required "source" (Json.Decode.string)
    |> required "difficulty" (Json.Decode.string)
    |> required "conclusion" (Json.Decode.string)
    |> required "created_by" (Json.Decode.nullable (Json.Decode.string))
    |> required "last_modified_by" (Json.Decode.nullable (Json.Decode.string))
    |> required "tags" (Json.Decode.nullable (Json.Decode.list (Json.Decode.string)))
    |> required "created_dt" (Json.Decode.nullable date)
    |> required "modified_dt" (Json.Decode.nullable date)
    |> required "text_sections" (Json.Decode.map Array.fromList (textSectionsDecoder))

nextDecoder : Json.Decode.Decoder CmdResp
nextDecoder =
  Json.Decode.map NextResp (Json.Decode.field "result" Json.Decode.bool)

ws_resp_decoder : Json.Decode.Decoder CmdResp
ws_resp_decoder =
  Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen command_decoder

command_decoder : String -> Json.Decode.Decoder CmdResp
command_decoder cmd_str =
  case cmd_str of
    "start" ->
      startDecoder
    "next" ->
      nextDecoder
    "text" ->
      Json.Decode.map TextResp (Json.Decode.field "result" textDecoder)
    _ ->
      Json.Decode.fail ("Command " ++ cmd_str ++ " not supported")