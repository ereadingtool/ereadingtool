import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http
import HttpHelpers exposing (post_with_headers, put_with_headers, delete_with_headers)

import Flags

import Profile
import Instructor.Profile

import Dict exposing (Dict)
import Views

import Ports

import Menu.Msg as MenuMsg
import Menu.Logout

type alias Word = String

type alias Meaning = {
   language : String
 , text : String
 }

type alias Flags = {
   csrftoken : Flags.CSRFToken
 , instructor_profile : Instructor.Profile.InstructorProfileParams
 , word_frequencies: List (Word, Int)
 , words : List (Word, Maybe (List Meaning)) }

type Msg =
    LogOut MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Model = {
   flags: Flags
 , definitions: Dict String (Maybe (List Meaning))
 , frequencies: Dict String Int
 , profile: Instructor.Profile.InstructorProfile
 }

init : Flags -> (Model, Cmd Msg)
init flags =
  ({
    flags=flags
  , definitions=Dict.fromList flags.words
  , frequencies=Dict.fromList flags.word_frequencies
  , profile=Instructor.Profile.init_profile flags.instructor_profile
  }
  , Cmd.none)


subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    LogOut msg ->
      (model, Instructor.Profile.logout model.profile model.flags.csrftoken LoggedOut)

    LoggedOut (Ok logout_resp) ->
      (model, Ports.redirect logout_resp.redirect)

    LoggedOut (Err err) ->
      (model, Cmd.none)


view_meaning : Meaning -> Html Msg
view_meaning meaning =
  div [] [
    div [] [ Html.text (" :" ++ meaning.text) ]
  , div [] [ Html.text ("(" ++ meaning.language ++ ")") ]
  ]

view_word_definition : (Word,  Maybe (List Meaning)) -> Html Msg
view_word_definition (word, meanings) =
  div [] [
    Html.text word
  , (case meanings of
      Just meanings_list ->
        div [] (List.map view_meaning meanings_list)
      Nothing ->
        div [] [Html.text "Undefined"]
    )
  ]


view_content : Model -> Html Msg
view_content model =
  div [] (List.map view_word_definition (Dict.toList model.definitions))

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view : Model -> Html Msg
view model =
  div [] [
    Views.view_header (Profile.fromInstructorProfile model.profile) Nothing LogOut
  , view_content model
  ]
