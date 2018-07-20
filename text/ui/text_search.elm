import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import HtmlParser
import HtmlParser.Util

import Http exposing (..)

import Array exposing (Array)

import Text.Model as Texts exposing (Text)

import Views
import Profile
import Instructor.Profile

import Config exposing (..)
import Flags exposing (CSRFToken)

-- UPDATE
type Msg = None

type alias Flags = Flags.Flags {}

type alias Model = {
    results : Array Text
  , profile : Profile.Profile
  , flags : Flags }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    results=Array.fromList []
  , profile=Profile.init_profile flags
  , flags=flags}, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    None ->
      (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_content : Model -> Html Msg
view_content model = div [] []

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
