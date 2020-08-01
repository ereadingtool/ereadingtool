module User.Student.Profile.Update exposing (update)

--

import Dict
import Http exposing (..)
import Json.Decode
import Ports
import User.Student.Profile as StudentProfile
import User.Student.Profile.Help as StudentProfileHelp
import User.Student.Profile.Model exposing (Model)
import User.Student.Profile.Msg exposing (Msg)
import User.Student.Profile.Resource as StudentProfileResource
import User.Student.Resource as StudentResource


toggleUsernameUpdate : Model -> Model
toggleUsernameUpdate model =
    { model
        | editing =
            if Dict.member "username" model.editing then
                Dict.remove "username" model.editing

            else
                Dict.insert "username" True model.editing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        validateUsername =
            StudentProfileResource.validateUsername
                model.flags.csrftoken
                model.student_endpoints.student_username_validation_uri

        updateProfile =
            StudentProfileResource.updateProfile model.flags.csrftoken model.student_endpoints.student_endpoint_uri

        toggleResearchConsent =
            StudentProfileResource.toggleResearchConsent
                model.flags.csrftoken
                model.student_endpoints.student_research_consent_uri
                model.profile
    in
    case msg of
        RetrieveStudentProfile (Ok profile) ->
            let
                username_update =
                    model.username_update

                new_username_update =
                    { username_update | username = StudentProfile.studentUserName profile }
            in
            ( { model | profile = profile, username_update = new_username_update }, Cmd.none )

        -- handle user-friendly msgs
        RetrieveStudentProfile (Err _) ->
            ( { model | err_str = "Error retrieving student profile!" }, Cmd.none )

        UpdateUsername value ->
            let
                username_update =
                    model.username_update

                new_username_update =
                    { username_update | username = Just (StudentResource.toStudentUsername value) }
            in
            ( { model | username_update = new_username_update }, validateUsername value )

        ValidUsername (Ok username_update) ->
            ( { model | username_update = username_update }, Cmd.none )

        ValidUsername (Err error) ->
            case error of
                Http.BadStatus resp ->
                    case Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body of
                        Ok errors ->
                            ( { model | errors = errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload badPayloadError _ ->
                    let
                        _ =
                            Debug.log "bad payload" badPayloadError
                    in
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateDifficulty difficulty ->
            let
                new_difficulty_preference =
                    ( difficulty, difficulty )

                new_student_profile =
                    StudentProfile.setStudentDifficultyPreference model.profile new_difficulty_preference
            in
            ( model, updateProfile new_student_profile )

        ToggleUsernameUpdate ->
            ( toggleUsernameUpdate model, Cmd.none )

        ToggleResearchConsent ->
            ( model, toggleResearchConsent (not model.consenting_to_research) )

        SubmitUsernameUpdate ->
            case model.username_update.username of
                Just username ->
                    let
                        profile =
                            StudentProfile.setUserName model.profile username
                    in
                    ( { model | profile = profile }, updateProfile profile )

                Nothing ->
                    ( model, Cmd.none )

        CancelUsernameUpdate ->
            ( toggleUsernameUpdate model, Cmd.none )

        Submitted (Ok student_profile) ->
            ( { model | profile = student_profile, editing = Dict.fromList [] }, Cmd.none )

        Submitted (Err err) ->
            let
                _ =
                    Debug.log "submitted error" err
            in
            case err of
                Http.BadStatus resp ->
                    case Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body of
                        Ok errors ->
                            ( { model | errors = errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload _ _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SubmittedConsent (Ok resp) ->
            ( { model | consenting_to_research = resp.consented }, Cmd.none )

        SubmittedConsent (Err err) ->
            let
                _ =
                    Debug.log "submitted error" err
            in
            case err of
                Http.BadStatus resp ->
                    case Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body of
                        Ok errors ->
                            ( { model | errors = errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload _ _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CloseHelp help_msg ->
            ( { model | help = StudentProfileHelp.setVisible model.help help_msg False }, Cmd.none )

        PrevHelp ->
            ( { model | help = StudentProfileHelp.prev model.help }, StudentProfileHelp.scrollToPrevMsg model.help )

        NextHelp ->
            ( { model | help = StudentProfileHelp.next model.help }, StudentProfileHelp.scrollToNextMsg model.help )

        Logout _ ->
            ( model, StudentProfileResource.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err err) ->
            let
                _ =
                    Debug.log "log out error" err
            in
            ( model, Cmd.none )
