import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)

import Dict exposing (Dict)

import Views exposing (view_filter, view_header, view_footer)
import Flags exposing (CSRFToken, Flags)


-- UPDATE
type Msg = Update

type alias Model = {
    flags : Flags
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , errors = Dict.fromList [] }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  Update -> (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_content : Model -> Html Msg
view_content model = Html.div [ classList [] ] [
    Html.div [classList [] ] <|
        [Html.text "instructor profile"]
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_content model)
  , (view_footer)
  ]
