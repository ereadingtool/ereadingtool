module Instructor.Instructor_Profile exposing (main, subscriptions, update, updateNewInviteEmail, view)

import Dict
import Html exposing (Html, div)
import Instructor.Invite exposing (Email)
import Instructor.Profile
import Instructor.Profile.Flags exposing (Flags)
import Instructor.Profile.Init
import Instructor.Profile.Model exposing (Model)
import Instructor.Profile.Msg exposing (Msg(..))
import Instructor.Profile.View
import Ports
import User.Profile
import Views

import Browser


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


updateNewInviteEmail : Model -> Email -> Model
updateNewInviteEmail model email =
    let
        validated_errors =
            if Instructor.Invite.isValidEmail email || Instructor.Invite.isEmptyEmail email then
                Dict.remove "invite" model.errors

            else
                Dict.insert "invite" "This e-mail is invalid." model.errors
    in
    { model | new_invite_email = Just email, errors = validated_errors }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        submitInvite =
            Instructor.Profile.submitNewInvite model.flags.csrftoken model.instructor_invite_uri SubmittedNewInvite
    in
    case msg of
        UpdateNewInviteEmail email ->
            let
                _ =
                    Debug.log "erorrs" model.errors
            in
            ( updateNewInviteEmail model email, Cmd.none )

        SubmitNewInvite ->
            ( model
            , case model.new_invite_email of
                Just email ->
                    submitInvite email

                Nothing ->
                    Cmd.none
            )

        SubmittedNewInvite (Ok invite) ->
            ( { model | profile = Instructor.Profile.addInvite model.profile invite }, Cmd.none )

        SubmittedNewInvite (Err err) ->
            let
                _ =
                    Debug.log "error inviting" err
            in
            ( { model | errors = Dict.insert "invite" "Something went wrong." model.errors }, Cmd.none )

        LogOut _ ->
            ( model, Instructor.Profile.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err _) ->
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Browser.element
        { init = Instructor.Profile.Init.init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Views.view_authed_header (User.Profile.fromInstructorProfile model.profile) model.menu_items LogOut
        , Instructor.Profile.View.view_content model
        , Views.view_footer
        ]
