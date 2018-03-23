import Html exposing (..)

import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (..)

import Http exposing (..)

import Array exposing (..)

import Date exposing (..)

import Markdown

import Time exposing (Time, second)

import Json.Decode exposing (int, string, float, list, succeed, Decoder)
import Json.Decode.Extra exposing (date)
import Json.Decode.Pipeline exposing (decode, required, optional, resolve, hardcoded)


type alias Text = {
    id: Int
  , title: String
  , created_dt: Date
  , modified_dt: Date
  , source: String
  , difficulty: String
  , question_count : Int
  , body : String }


type alias Texts = List Text

-- MODEL
type alias Model = { texts : List Text }

-- ENDPOINT
api_endpoint : String
api_endpoint = "/api/text/"

-- UPDATE
type Msg = Update (Result Http.Error (List Text))

type alias Filter = List String

init : (Model, Cmd Msg)
init = (Model  [], updateTexts [])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


textDecoder : Decoder Text
textDecoder =
  decode Text
    |> required "id" int
    |> required "title" string
    |> required "created_dt" date
    |> required "modified_dt" date
    |> required "source" string
    |> required "difficulty" string
    |> required "question_count" int
    |> required "body" string

textsDecoder : Decoder (List Text)
textsDecoder = list textDecoder

updateTexts : Filter -> Cmd Msg
updateTexts filter = let request = Http.get api_endpoint textsDecoder in
  Http.send Update request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update (Ok texts) ->
      (Model texts, Cmd.none)
    -- handle user-friendly msgs
    Update (Err _) ->
      (model, Cmd.none)


main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_header : Model -> Html Msg
view_header model =
    div [ classList [("header", True)] ] [
        text "E-Reader"
      , div [ classList [("menu", True)] ] [
          span [ classList [("menu_item", True)] ] [
            text ""
          ]
        ]
    ]

view_filter : Model -> Html Msg
view_filter model = div [classList [("filter_items", True)] ] [
     div [classList [("filter", True)] ] [
         Html.input [attribute "placeholder" "Search texts.."] []
       , Html.button [] [Html.text "Create Text"]
     ]
 ]

month_day_year_fmt : Date -> String
month_day_year_fmt date = List.foldr (++) "" <| List.map (\s -> s ++ "  ")
  [toString <| Date.month date, (toString <| Date.day date) ++ ",", toString <| Date.year date]


view_text : Text -> Html Msg
view_text text = div [ classList[("text_item", True)] ] [
     div [classList [("item_property", True)], attribute "data-id" (toString text.id)] [ Html.text "" ]
   , div [classList [("item_property", True)]] [
       Html.text text.title
     , span [classList [("sub_description", True)]] [
         Html.text <| "Modified:   " ++ month_day_year_fmt text.modified_dt
       ]
     ]
   , div [classList [("item_property", True)]] [
       Html.text text.difficulty
       , span [classList [("sub_description", True)]] [
             Html.text "Difficulty"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text <| toString text.question_count
        , span [classList [("sub_description", True)]] [
             Html.text "Questions"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text "1"
        , span [classList [("sub_description", True)]] [
             Html.text "Languages"
           ]
     ]   , div [classList [("action_menu", True)]] [ Html.text "" ]
 ]

view_texts : Model -> Html Msg
view_texts model = div [classList [("text_items", True)] ]
   (List.map view_text model.texts)

view_footer : Model -> Html Msg
view_footer model = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text <| "Showing " ++ toString (List.length model.texts) ++ " entries"
    ]
 ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header model)
  , (view_filter model)
  , (view_texts model)
  , (view_footer model)
  ]
