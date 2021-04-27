module Vote exposing
    ( Vote(..)
    , VoteResponse
    , decoder
    , encode
    , voteResponseDecoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)


type Vote
    = Up
    | Down
    | None


type alias VoteResponse =
    { textId : Int
    , vote : Vote
    , rating : Int
    }


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


voteResponseDecoder : Decoder VoteResponse
voteResponseDecoder =
    Decode.succeed VoteResponse
        |> required "textId" Decode.int
        |> required "vote" decoder
        |> required "rating" Decode.int


encode : Vote -> Value
encode vote =
    Encode.object
        [ ( "vote", Encode.string (voteToString vote) )
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
