module Utils exposing
    ( intTupleDecoder
    , isValidEmail
    , onEnterUp
    , stringTupleDecoder
    )

import Email
import Html
import Html.Events
import Json.Decode


isValidEmail : String -> Bool
isValidEmail addr =
    Email.isValid addr


stringTupleDecoder : Json.Decode.Decoder ( String, String )
stringTupleDecoder =
    Json.Decode.map2 (\a b -> ( a, b )) (Json.Decode.index 0 Json.Decode.string) (Json.Decode.index 1 Json.Decode.string)


intTupleDecoder : Json.Decode.Decoder ( Int, Int )
intTupleDecoder =
    Json.Decode.map2 (\a b -> ( a, b )) (Json.Decode.index 0 Json.Decode.int) (Json.Decode.index 1 Json.Decode.int)


onEnterUp : msg -> Html.Attribute msg
onEnterUp msg =
    Html.Events.on
        "keyup"
        (Html.Events.keyCode
            |> Json.Decode.andThen
                (\key ->
                    if key == 13 then
                        Json.Decode.succeed msg

                    else
                        Json.Decode.fail "not enter key"
                )
        )
