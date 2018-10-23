module TextReader.Encode exposing (..)

import TextReader.Model exposing (..)
import TextReader.Answer.Model
import Json.Encode


jsonToString : (Json.Encode.Value -> String)
jsonToString = (Json.Encode.encode 0)

send_command : CmdReq -> Json.Encode.Value
send_command cmd_req =
  case cmd_req of
    NextReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "next")
      ]

    PrevReq ->
      Json.Encode.object [
        ("command", Json.Encode.string  "prev")
      ]

    AnswerReq text_answer ->
      let
        text_reader_answer = TextReader.Answer.Model.answer text_answer
      in
        Json.Encode.object [
          ("command", Json.Encode.string "answer")
        , ("answer_id", Json.Encode.int text_reader_answer.id)
        ]

    AddToFlashcardsReq reader_word ->
      Json.Encode.object [
        ("command", Json.Encode.string "add_flashcard_word")
      , ("word", Json.Encode.string reader_word.word)
      ]

    RemoveFromFlashcardsReq reader_word ->
      Json.Encode.object [
        ("command", Json.Encode.string "remove_flashcard_word")
      , ("word", Json.Encode.string reader_word.word)
      ]