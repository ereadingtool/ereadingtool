module Instructor.Profile.View exposing (view_content)

import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onInput)
import Instructor.Invite
import Instructor.Profile
import Instructor.Profile.Model exposing (Model)
import Instructor.Profile.Msg exposing (Msg(..))


view_tags : List Instructor.Profile.Tag -> List (Html Msg)
view_tags tags =
    List.map (\tag -> div [] [ Html.text tag ]) tags


view_text : Instructor.Profile.InstructorProfile -> Instructor.Profile.Text -> Html Msg
view_text instructor_profile text =
    let
        instructor_username =
            Instructor.Profile.usernameToString (Instructor.Profile.username instructor_profile)
    in
    div [ class "text" ]
        [ div [ class "text_label" ] [ Html.text "Title" ]
        , div [ class "text_value" ] [ Html.text text.title ]
        , div [ class "text_label" ] [ Html.text "Difficulty" ]
        , div [ class "text_value" ] [ Html.text text.difficulty ]
        , div [ class "text_label" ] [ Html.text "Sections" ]
        , div [ class "text_value" ] [ Html.text (String.fromInt text.text_section_count) ]
        , div [ class "text_label" ] [ Html.text "Created/Modified" ]
        , div [ class "text_value" ]
            [ if text.created_by == instructor_username then
                div [] [ Html.text "Created by you" ]

              else
                div [] [ Html.text "Last modified by you on ", div [] [ Html.text text.modified_dt ] ]
            ]
        , div [ class "text_label" ] [ Html.text "Tags" ]
        , div [ class "text_value" ] (view_tags text.tags)
        , div [ class "text_label" ] [ Html.a [ attribute "href" text.edit_uri ] [ Html.text "Edit Text" ] ]
        , div [] []
        ]


view_instructor_invite : Instructor.Invite.InstructorInvite -> Html Msg
view_instructor_invite invite =
    div [ class "invite" ]
        [ div [ class "label" ] [ Html.text "Email: " ]
        , div [ class "value" ] [ Html.text (Instructor.Invite.emailToString (Instructor.Invite.email invite)) ]
        , div [ class "label" ] [ Html.text "Invite Code: " ]
        , div [ class "value" ] [ Html.text (Instructor.Invite.codeToString (Instructor.Invite.inviteCode invite)) ]
        , div [ class "label" ] [ Html.text "Expiration: " ]
        , div [ class "value" ] [ Html.text (Instructor.Invite.expirationToString (Instructor.Invite.inviteExpiration invite)) ]
        ]


view_instructor_invite_create : Model -> Html Msg
view_instructor_invite_create model =
    let
        has_error =
            Dict.member "invite" model.errors

        error_attrs =
            if has_error then
                [ attribute "class" "input_error" ]

            else
                []

        error_msg =
            div [] [ Html.text (Maybe.withDefault "" (Dict.get "invite" model.errors)) ]
    in
    div [ id "create_invite" ]
        [ div [ id "input" ] <|
            [ Html.input
                ([ attribute "size" "25"
                 , onInput (Instructor.Invite.Email >> UpdateNewInviteEmail)
                 , attribute "placeholder" "Invite an instructor"
                 ]
                    ++ error_attrs
                )
                []
            ]
                ++ (if has_error then
                        [ error_msg ]

                    else
                        []
                   )
        , div [ id "submit" ]
            [ Html.input [ onClick SubmitNewInvite, attribute "type" "button", attribute "value" "Submit" ] []
            ]
        ]


view_instructor_invites : Model -> List (Html Msg)
view_instructor_invites model =
    if Instructor.Profile.isAdmin model.profile then
        let
            invites =
                Maybe.withDefault [] (Instructor.Profile.invites model.profile)
        in
        [ div [ class "invites" ]
            [ span [ class "profile_item_title" ] [ Html.text "Invitations" ]
            , span [ class "profile_item_value" ]
                [ div [ class "list" ] <|
                    List.map view_instructor_invite invites
                        ++ [ view_instructor_invite_create model ]
                ]
            ]
        ]

    else
        []


view_texts : Model -> Html Msg
view_texts model =
    div [] (List.map (\text -> view_text model.profile text) (Instructor.Profile.texts model.profile))


view_content : Model -> Html Msg
view_content model =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ classList [ ( "profile_items", True ) ] ] <|
            [ div [ class "profile_item" ]
                [ span [ class "profile_item_title" ] [ Html.text "Username" ]
                , span [ class "profile_item_value" ]
                    [ Html.text (Instructor.Profile.usernameToString (Instructor.Profile.username model.profile))
                    ]
                ]
            , div [ class "profile_item" ]
                [ span [ class "profile_item_title" ] [ Html.text "Texts" ]
                , span [ class "profile_item_value" ] [ view_texts model ]
                ]
            ]
                ++ view_instructor_invites model
        ]
