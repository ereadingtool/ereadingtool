import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)

import Http exposing (..)

import Array exposing (Array)

import Model exposing (Text, Question, emptyText, textDecoder)
import Views exposing (view_filter, view_header, view_footer)
import Config exposing (..)
import Flags exposing (CSRFToken)

-- UPDATE
type Msg = Update (Result Http.Error Text)

type alias Flags = {
    csrftoken : CSRFToken
  , quiz_id : Int }

type alias Model = {
    text : Text
  , flags : Flags }

init : Flags -> (Model, Cmd Msg)
init flags = (Model emptyText flags, (updateText flags.quiz_id))

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateText : Int -> Cmd Msg
updateText text_id = let request = Http.get (String.join "" [text_api_endpoint, (toString text_id)]) textDecoder
  in
   Http.send Update request

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update (Ok text) ->
      ({ model | text = text }, Cmd.none)
    -- handle user-friendly msgs
    Update (Err err) -> case (Debug.log "error" err) of
      _ -> (model, Cmd.none)


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_text : Text -> Html Msg
view_text text = div [ classList[("text", True)] ] [
    div [classList [("text_body", True)]] [ Html.iframe [attribute "srcdoc" text.body] [ ] ]
 ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_text model.text)
  , (view_footer)
  ]
