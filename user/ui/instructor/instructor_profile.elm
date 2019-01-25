import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)
import Html.Events exposing (onClick, onInput)

import HttpHelpers

import Dict exposing (Dict)

import Http

import Views
import Flags

import User.Profile
import Instructor.Profile

import Json.Encode
import Json.Decode

import Menu.Msg as MenuMsg
import Menu.Logout

import Ports

import Http

import Util exposing (is_valid_email)

-- UPDATE
type Msg =
   UpdateNewInviteEmail Email
 | SubmittedNewInvite (Result Http.Error Instructor.Profile.Invite)
 | SubmitNewInvite
 | LogOut MenuMsg.Msg
 | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = {
   csrftoken : Flags.CSRFToken
 , instructor_profile : Instructor.Profile.InstructorProfileParams }

type alias Email = String

type alias NewInviteResp = {
   email : Email
 , invite_code : String
 }

type alias NewInvite = {
  email : Email }

type alias Model = {
    flags : Flags
  , profile : Instructor.Profile.InstructorProfile
  , new_invite : NewInvite
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile = Instructor.Profile.init_profile flags.instructor_profile
  , new_invite = {email=""}
  , errors = Dict.empty }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateNewInviteEmail : Model -> Email -> Model
updateNewInviteEmail model email =
  let
    new_invite = model.new_invite

    validated_errors =
      (if (is_valid_email email) || (email == "") then
        Dict.remove "invite" model.errors
      else
        Dict.insert "invite" "This e-mail is invalid." model.errors)
  in
    { model | new_invite = {new_invite | email = email}, errors = validated_errors }

newInviteEncoder : NewInvite -> Json.Encode.Value
newInviteEncoder new_invite =
  Json.Encode.object [
    ("email", Json.Encode.string new_invite.email)
  ]

newInviteRespDecoder : Json.Decode.Decoder Instructor.Profile.Invite
newInviteRespDecoder =
  Json.Decode.map3 Instructor.Profile.Invite
    (Json.Decode.field "email" Json.Decode.string)
    (Json.Decode.field "invite_code" Json.Decode.string)
    (Json.Decode.field "expiration" Json.Decode.string)

submitNewInvite : Model -> Cmd Msg
submitNewInvite model =
  case is_valid_email model.new_invite.email of
    True ->
      let
        encoded_new_invite = newInviteEncoder model.new_invite

        req =
          HttpHelpers.post_with_headers
           Instructor.Profile.inviteURI
           [Http.header "X-CSRFToken" model.flags.csrftoken]
           (Http.jsonBody encoded_new_invite) newInviteRespDecoder
      in
        Http.send SubmittedNewInvite req

    False ->
      Cmd.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateNewInviteEmail email -> let _ = Debug.log "erorrs" model.errors in
      (updateNewInviteEmail model email, Cmd.none)

    SubmitNewInvite ->
      (model, submitNewInvite model)

    SubmittedNewInvite (Ok invite) ->
      ({ model | profile = Instructor.Profile.addInvite model.profile invite}, Cmd.none)

    SubmittedNewInvite (Err err) -> let _ = Debug.log "error inviting" err in
      ({ model | errors = (Dict.insert "invite" "Something went wrong." model.errors)}, Cmd.none)

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

view_instructor_invite : Instructor.Profile.Invite -> Html Msg
view_instructor_invite invite =
  div [class "invite"] [
    div [class "label"] [ Html.text "Email: " ]
  , div [class "value"] [ Html.text invite.email ]
  , div [class "label"] [ Html.text "Invite Code: " ]
  , div [class "value"] [ Html.text invite.invite_code ]
  , div [class "label"] [ Html.text "Expiration: " ]
  , div [class "value"] [ Html.text invite.expiration ]
  ]

view_instructor_invite_create : Model -> Html Msg
view_instructor_invite_create model =
  let
    has_error = Dict.member "invite" model.errors

    error_attrs =
      if has_error then
        [attribute "class" "input_error"]
      else
        []

    error_msg =
      div [] [ Html.text (Maybe.withDefault "" (Dict.get "invite" model.errors)) ]
  in
    div [id "create_invite"] [
      div [id "input"] <| [
        Html.input
          ([attribute "size" "25"
          , onInput UpdateNewInviteEmail
          , attribute "placeholder" "Invite an instructor"] ++ (error_attrs)) []
      ] ++ (if has_error then [error_msg] else [])
    , div [id "submit"] [
        Html.input [onClick SubmitNewInvite, attribute "type" "button", attribute "value" "Submit"] []
      ]
    ]

view_instructor_invites : Model -> List (Html Msg)
view_instructor_invites model =
  case Instructor.Profile.invites model.profile of
    Just invites -> [
        div [class "invites"] [
          span [class "profile_item_title"] [ Html.text "Invitations" ]
        , span [class "profile_item_value"] [
            div [class "list"] <|
              (List.map view_instructor_invite invites) ++ [view_instructor_invite_create model]
          ]
        ]
      ]

    Nothing ->
      []

view_texts : Model -> Html Msg
view_texts model =
  div [] (List.map (\text -> (view_text model.profile) text) (Instructor.Profile.texts model.profile))

view_content : Model -> Html Msg
view_content model =
  div [ classList [("profile", True)] ] [
    div [classList [("profile_items", True)] ] <| [
      div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Username" ]
      , span [class "profile_item_value"] [ Html.text (Instructor.Profile.username model.profile) ]
      ]
    , div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Texts" ]
      , span [class "profile_item_value"] [ view_texts model ]
      ]
    ] ++
      (case Instructor.Profile.invites model.profile of
         Just _ ->
           view_instructor_invites model

         Nothing -> [])
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_authed_header (User.Profile.fromInstructorProfile model.profile) Nothing LogOut)
  , (view_content model)
  , (Views.view_footer)
  ]
