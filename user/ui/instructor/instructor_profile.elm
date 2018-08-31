import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)

import Dict exposing (Dict)

import Views
import Flags

import Profile
import Instructor.Profile

import Menu.Msg as MenuMsg

-- UPDATE
type Msg =
   Update
 | Logout MenuMsg.Msg

type alias Flags = Flags.Flags {}

type alias Model = {
    flags : Flags
  , profile : Profile.Profile
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile=Profile.init_profile flags
  , errors = Dict.fromList [] }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update ->
      (model, Cmd.none)
    Logout msg ->
      (model, Instructor.Profile.logout model.profile)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_content : Model -> Html Msg
view_content model =
  div [ classList [] ] [
    div [classList [] ] [
      Html.text "instructor profile"
    ]
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing Logout)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
