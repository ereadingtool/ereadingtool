module Flashcard.Encode exposing (..)

import Flashcard.Mode
import Flashcard.Model exposing (..)
import Json.Encode


jsonToString : Json.Encode.Value -> String
jsonToString =
    Json.Encode.encode 0


commandRequestToString : CmdReq -> String
commandRequestToString cmdReq =
    jsonToString <| sendCommand cmdReq


sendCommand : CmdReq -> Json.Encode.Value
sendCommand cmdReq =
    case cmdReq of
        ChooseModeReq mode ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "choose_mode" )
                , ( "mode", Json.Encode.string (Flashcard.Mode.modeId mode) )
                ]

        NextReq ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "next" )
                ]

        StartReq ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "start" )
                ]

        ReviewAnswerReq ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "review_answer" )
                ]

        AnswerReq answer ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "answer" )
                , ( "answer", Json.Encode.string answer )
                ]

        RateQualityReq q ->
            Json.Encode.object
                [ ( "command", Json.Encode.string "rate_quality" )
                , ( "rating", Json.Encode.int q )
                ]

        _ ->
            Json.Encode.object []
