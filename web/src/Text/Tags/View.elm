module Text.Tags.View exposing (view_tags)

import Dict exposing (Dict)
import Html exposing (Attribute, Html, datalist, div, option)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick)
import Text.Field


type alias ID =
    String


type alias Tag =
    String


view_tag : (String -> msg) -> String -> Html msg
view_tag delete_msg tag =
    div [ class "text_tag" ]
        [ Html.img
            [ attribute "src" "/public/img/cancel.svg"
            , attribute "height" "13px"
            , attribute "width" "13px"
            , class "cursor"
            , onClick (delete_msg tag)
            ]
            []
        , Html.text tag
        ]


view_tags : ID -> List Tag -> Dict Tag Tag -> ( Attribute msg, String -> msg ) -> Text.Field.TextFieldAttributes -> Html msg
view_tags id tag_list tags ( add_msg, delete_msg ) text_tag_attrs =
    div [ attribute "id" "text_tags", classList [ ( "input_error", text_tag_attrs.error ) ] ]
        [ datalist [ attribute "id" "tag_list", attribute "type" "text" ] <|
            List.map (\tag -> option [ attribute "value" tag ] [ Html.text tag ]) tag_list
        , div [ class "text_tags" ] (List.map (view_tag delete_msg) (Dict.keys tags))
        , div []
            [ Html.input
                [ attribute "id" id
                , attribute "placeholder" "add tags.."
                , attribute "list" "tag_list"
                , add_msg
                ]
                []
            ]
        , div [ classList [ ( "error", text_tag_attrs.error ) ] ] [ Html.text text_tag_attrs.error_string ]
        ]
