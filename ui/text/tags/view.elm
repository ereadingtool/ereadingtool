module Text.Tags.View exposing (view_tags)

import Dict exposing (Dict)

import Html exposing (..)

import Html exposing (div)
import Html.Events exposing (onClick)

import Html.Attributes exposing (attribute, class)

type alias ID = String
type alias Tag = String

view_tag : (String -> msg) -> String -> Html msg
view_tag delete_msg tag =
  div [class "text_tag"] [
    Html.img [
      attribute "src" "/static/img/cancel.svg"
    , attribute "height" "13px"
    , attribute "width" "13px"
    , class "cursor"
    , onClick (delete_msg tag)
    ] [], Html.text tag ]

view_tags : ID -> List Tag -> Dict Tag Tag -> (Attribute msg, String -> msg) -> Html msg
view_tags id tag_list tags (add_msg, delete_msg) =
  div [attribute "id" "text_tags"] [
    datalist [attribute "id" "tag_list", attribute "type" "text"] <|
      List.map (\tag -> option [attribute "value" tag] [ Html.text tag ]) tag_list
        , div [class "text_tags"] (List.map (view_tag delete_msg) (Dict.keys tags))
        , div [] [
            Html.input [
              attribute "id" id
            , attribute "placeholder" "add tags.."
            , attribute "list" "tag_list"
            , add_msg
            ] []
          ]
  ]