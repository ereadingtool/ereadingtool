module User.Instructor.Profile.View exposing (view_content)

import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onInput)
import User.Instructor.Invite as InstructorInvite exposing (InstructorInvite)
import User.Instructor.Profile as InstructorProfile exposing (InstructorProfile)
import User.Instructor.Profile.Model exposing (Model)
import User.Instructor.Profile.Msg exposing (Msg(..))


view_tags : List InstructorProfile.Tag -> List (Html Msg)
view_tags tags =
    List.map (\tag -> div [] [ Html.text tag ]) tags


view_text : InstructorProfile -> InstructorProfile.Text -> Html Msg
view_text instructor_profile text =
    let
        instructor_username =
            InstructorProfile.usernameToString (InstructorProfile.username instructor_profile)
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


view_instructor_invite : InstructorInvite -> Html Msg
view_instructor_invite invite =
    div [ class "invite" ]
        [ div [ class "label" ] [ Html.text "Email: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.emailToString (InstructorInvite.email invite)) ]
        , div [ class "label" ] [ Html.text "Invite Code: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.codeToString (InstructorInvite.inviteCode invite)) ]
        , div [ class "label" ] [ Html.text "Expiration: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.expirationToString (InstructorInvite.inviteExpiration invite)) ]
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
                 , onInput (InstructorInvite.Email >> UpdateNewInviteEmail)
                 , attribute "placeholder" "Invite a content editor"
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
    if InstructorProfile.isAdmin model.profile then
        let
            invites =
                Maybe.withDefault [] (InstructorProfile.invites model.profile)
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
    div [] (List.map (\text -> view_text model.profile text) (InstructorProfile.texts model.profile))


view_content : Model -> Html Msg
view_content model =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ classList [ ( "profile_items", True ) ] ] <|
            [ div [ class "profile_item" ]
                [ span [ class "profile_item_title" ] [ Html.text "Username" ]
                , span [ class "profile_item_value" ]
                    [ Html.text (InstructorProfile.usernameToString (InstructorProfile.username model.profile))
                    ]
                ]
            , div [ class "profile_item" ]
                [ span [ class "profile_item_title" ] [ Html.text "Texts" ]
                , span [ class "profile_item_value" ] [ view_texts model ]
                ]
            ]
                ++ view_instructor_invites model
        ]
