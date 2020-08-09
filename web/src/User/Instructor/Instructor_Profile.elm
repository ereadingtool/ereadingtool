module User.Instructor.Instructor_Profile exposing (main, subscriptions, update, updateNewInviteEmail, view)

import Browser
import Dict
import Html exposing (Html, div)
import Ports
import User.Instructor.Invite exposing (Email)
import User.Instructor.Profile as InstructorProfile
import User.Instructor.Profile.Flags exposing (Flags)
import User.Instructor.Profile.Init as InstructorProfileInit
import User.Instructor.Profile.Model exposing (Model)
import User.Instructor.Profile.Msg exposing (Msg(..))
import User.Instructor.Profile.View as InstructorProfileView
import User.Profile
import Views


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


updateNewInviteEmail : Model -> Email -> Model
updateNewInviteEmail model email =
    let
        validated_errors =
            if User.Instructor.Invite.isValidEmail email || User.Instructor.Invite.isEmptyEmail email then
                Dict.remove "invite" model.errors

            else
                Dict.insert "invite" "This e-mail is invalid." model.errors
    in
    { model | new_invite_email = Just email, errors = validated_errors }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        submitInvite =
            InstructorProfile.submitNewInvite (Api.Endpoint.instructorInviteEndpoint model.config) SubmittedNewInvite
    in
    case msg of
        UpdateNewInviteEmail email ->
            let
                _ =
                    Debug.log "errors" model.errors
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
            ( { model | profile = InstructorProfile.addInvite model.profile invite }, Cmd.none )

        SubmittedNewInvite (Err err) ->
            let
                _ =
                    Debug.log "error inviting" err
            in
            ( { model | errors = Dict.insert "invite" "Something went wrong." model.errors }, Cmd.none )

        LogOut _ ->
            ( model, InstructorProfile.logout model.config LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err _) ->
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Browser.element
        { init = InstructorProfileInit.init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Views.view_authed_header (User.Profile.fromInstructorProfile model.profile) model.menu_items LogOut
        , InstructorProfileView.view_content model
        , Views.view_footer
        ]
