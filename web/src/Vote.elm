module Vote exposing
    ( Vote(..)
    , decoder
    , encode
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type Vote
    = Up
    | Down
    | None


decoder : Decoder Vote
decoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "up" ->
                        Decode.succeed Up

                    "down" ->
                        Decode.succeed Down

                    "none" ->
                        Decode.succeed None

                    _ ->
                        Decode.fail "Not a valid vote"
            )


encode : Vote -> Value
encode vote =
    Encode.object
        [ ( "rating", Encode.string (voteToString vote) )
        ]


voteToString : Vote -> String
voteToString vote =
    case vote of
        Up ->
            "up"

        Down ->
            "down"

        None ->
            "none"
