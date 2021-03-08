module TextReader.Encode exposing (..)

import Json.Encode
import TextReader.Answer.Model
import TextReader.Model exposing (..)


jsonToString : Json.Encode.Value -> String
jsonToString =
    Json.Encode.encode 0

commandRequestToString : CmdReq -> String
commandRequestToString cmdReq =
    jsonToString <| sendCommand cmdReq

sendCommand : CmdReq -> Json.Encode.Value
sendCommand cmdReq =
    case cmdReq of
        NextReq ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "next" )
                ]

        PrevReq ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "prev" )
                ]

        AnswerReq text_answer ->
            let
                textReaderAnswer =
                    TextReader.Answer.Model.answer text_answer
            in
            Json.Encode.object
                [ ( "command", Json.Encode.string "answer" )
                , ( "answer_id", Json.Encode.int textReaderAnswer.id )
                ]

        AddToFlashcardsReq reader_word ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "add_flashcard_phrase" )
                , ( "instance", Json.Encode.string (String.fromInt (TextReader.Model.instance reader_word)) )
                , ( "phrase", Json.Encode.string (TextReader.Model.phrase reader_word) )
                ]

        RemoveFromFlashcardsReq reader_word ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "remove_flashcard_phrase" )
                , ( "instance", Json.Encode.string (String.fromInt (TextReader.Model.instance reader_word)) )
                , ( "phrase", Json.Encode.string (TextReader.Model.phrase reader_word) )
                ]
