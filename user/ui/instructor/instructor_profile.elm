import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)

import Http

import Views
import Flags

import Profile
import Instructor.Profile

import Menu.Msg as MenuMsg
import Menu.Logout

import Ports

import Http

-- UPDATE
type Msg =
   Update
 | LogOut MenuMsg.Msg
 | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = {
   csrftoken : Flags.CSRFToken
 , instructor_profile : Instructor.Profile.InstructorProfileParams }

type alias Model = {
    flags : Flags
  , profile : Instructor.Profile.InstructorProfile
  , err_str : String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile=Instructor.Profile.init_profile flags.instructor_profile
  , err_str = "" }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update ->
      (model, Cmd.none)

    LogOut msg ->
      (model, Instructor.Profile.logout model.profile model.flags.csrftoken LoggedOut)

    LoggedOut (Ok logout_resp) ->
      (model, Ports.redirect logout_resp.redirect)

    LoggedOut (Err err) ->
      (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_tags : List Instructor.Profile.Tag -> List (Html Msg)
view_tags tags =
  List.map (\tag -> div [] [ Html.text tag ]) tags

view_text : Instructor.Profile.InstructorProfile -> Instructor.Profile.Text -> Html Msg
view_text instructor_profile text =
  let
    instructor_username = Instructor.Profile.username instructor_profile
  in
    div [class "text"] [
      div [class "text_label"] [ Html.text "Title" ]
    , div [class "text_value"] [ Html.text text.title ]

    , div [class "text_label"] [ Html.text "Difficulty"]
    , div [class "text_value"] [ Html.text text.difficulty ]

    , div [class "text_label"] [ Html.text "Sections"]
    , div [class "text_value"] [ Html.text (toString text.text_section_count) ]

    , div [class "text_label"] [ Html.text "Created/Modified" ]
    , div [class "text_value"] [
      (case text.created_by == instructor_username of
         True ->
           div [] [ Html.text "Created by you"]
         False ->
           div [] [ Html.text "Last modified by you on ", div [] [ Html.text text.modified_dt ] ])
      ]
    , div [class "text_label"] [ Html.text "Tags" ]
    , div [class "text_value"] (view_tags text.tags)

    , div [class "text_label"] [ Html.a [attribute "href" text.edit_uri] [ Html.text "Edit Text" ] ]
    , div [] []
    ]

view_texts : Model -> Html Msg
view_texts model =
  div [] (List.map (\text -> (view_text model.profile) text) (Instructor.Profile.texts model.profile))

view_content : Model -> Html Msg
view_content model =
  div [ classList [("profile", True)] ] [
    div [classList [("profile_items", True)] ] [
      div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Username" ]
      , span [class "profile_item_value"] [ Html.text (Instructor.Profile.username model.profile) ]
      ]
    , div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Texts" ]
      , span [class "profile_item_value"] [ view_texts model ]
      ]
    ]
    , (if not (String.isEmpty model.err_str) then
        span [attribute "class" "error"] [ Html.text "error", Html.text model.err_str ]
       else Html.text "")
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header (Profile.fromInstructorProfile model.profile) Nothing LogOut)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
