module Infobar exposing (Infobar, errorBottom, successBottom, view)

import Html exposing (..)
import Html.Attributes exposing (classList)


type alias Infobar =
    { status : Status
    , message : String
    , position : Position
    }


type Status
    = Success
    | Error


type Position
    = Top
    | Bottom


successBottom : String -> Infobar
successBottom message =
    { status = Success
    , message = message
    , position = Bottom
    }


errorBottom : String -> Infobar
errorBottom message =
    { status = Error
    , message = message
    , position = Bottom
    }


view : Infobar -> Html msg
view infobar =
    case infobar.position of
        Top ->
            div []
                [ div
                    [ classList
                        [ ( "infobar", True )
                        , ( "infobar-top", True )
                        , statusClass infobar.status
                        ]
                    ]
                    [ text infobar.message ]
                ]

        Bottom ->
            div []
                [ div
                    [ classList
                        [ ( "infobar", True )
                        , ( "infobar-bottom", True )
                        , statusClass infobar.status
                        ]
                    ]
                    [ text infobar.message ]
                ]


statusClass : Status -> ( String, Bool )
statusClass status =
    case status of
        Success ->
            ( "infobar-success", True )

        Error ->
            ( "infobar-error", True )
