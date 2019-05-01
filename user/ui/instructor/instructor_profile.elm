import Html exposing (Html, div, span)
import Html.Attributes exposing (id, class, classList, attribute)
import Html.Events exposing (onClick, onInput)

import Dict exposing (Dict)

import Http

import Views
import Flags

import User.Profile

import Instructor.Invite exposing (InstructorInvite, Email)

import Instructor.Resource
import Instructor.Profile

import Menu.Items
import Menu.Msg as MenuMsg
import Menu.Logout

import Ports

import Http

-- UPDATE
type Msg =
   UpdateNewInviteEmail Email
 | SubmittedNewInvite (Result Http.Error InstructorInvite)
 | SubmitNewInvite
 | LogOut MenuMsg.Msg
 | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags =
  Flags.AuthedFlags {
    instructor_invite_uri: String
  , instructor_profile : Instructor.Profile.InstructorProfileParams }


type alias Model = {
    flags : Flags
  , profile : Instructor.Profile.InstructorProfile
  , instructor_invite_uri : Instructor.Resource.InstructorInviteURI
  , menu_items : Menu.Items.MenuItems
  , new_invite_email : Maybe Email
  , errors : Dict String String }

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags=flags
  , instructor_invite_uri=Instructor.Resource.flagsToInstructorURI flags
  , profile=Instructor.Profile.initProfile flags.instructor_profile
  , menu_items=Menu.Items.initMenuItems flags
  , new_invite_email=Nothing
  , errors=Dict.empty }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

updateNewInviteEmail : Model -> Email -> Model
updateNewInviteEmail model email =
  let
    validated_errors =
      (if (Instructor.Invite.isValidEmail email) || (Instructor.Invite.isEmptyEmail email) then
        Dict.remove "invite" model.errors

       else
        Dict.insert "invite" "This e-mail is invalid." model.errors)
  in
    { model | new_invite_email = Just email, errors = validated_errors }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    submitInvite =
      Instructor.Profile.submitNewInvite model.flags.csrftoken model.instructor_invite_uri SubmittedNewInvite
  in
    case msg of
      UpdateNewInviteEmail email -> let _ = Debug.log "erorrs" model.errors in
        (updateNewInviteEmail model email, Cmd.none)

      SubmitNewInvite ->
        (model
        ,(case model.new_invite_email of
            Just email ->
              submitInvite email

            Nothing ->
              Cmd.none))

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
    instructor_username = Instructor.Profile.usernameToString (Instructor.Profile.username instructor_profile)
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

view_instructor_invite : InstructorInvite -> Html Msg
view_instructor_invite invite =
  div [class "invite"] [
    div [class "label"] [ Html.text "Email: " ]
  , div [class "value"] [ Html.text (Instructor.Invite.emailToString (Instructor.Invite.email invite)) ]
  , div [class "label"] [ Html.text "Invite Code: " ]
  , div [class "value"] [ Html.text (Instructor.Invite.codeToString (Instructor.Invite.inviteCode invite)) ]
  , div [class "label"] [ Html.text "Expiration: " ]
  , div [class "value"] [ Html.text (Instructor.Invite.expirationToString (Instructor.Invite.inviteExpiration invite)) ]
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
          , onInput (Instructor.Invite.Email >> UpdateNewInviteEmail)
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
      , span [class "profile_item_value"] [
          Html.text (Instructor.Profile.usernameToString (Instructor.Profile.username model.profile))
        ]
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
    (Views.view_authed_header (User.Profile.fromInstructorProfile model.profile) model.menu_items LogOut)
  , (view_content model)
  , (Views.view_footer)
  ]
