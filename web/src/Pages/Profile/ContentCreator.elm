module Pages.Profile.ContentCreator exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onInput)
import Http
import Http.Detailed
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Time exposing (Zone)
import User.Instructor.Invite as InstructorInvite exposing (Email, InstructorInvite)
import User.Instructor.Profile as InstructorProfile
    exposing
        ( InstructorProfile(..)
        , InstructorUsername(..)
        )
import User.Profile as Profile
import Utils.Date


page : Page Params Model Msg
page =
    Page.protectedInstructorApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { session : Session
        , config : Config
        , timezone : Zone
        , profile : InstructorProfile
        , newInviteEmail : Maybe InstructorInvite.Email
        , errors : Dict String String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , timezone = shared.timezone
        , profile = Profile.toInstructorProfile shared.profile
        , newInviteEmail = Nothing
        , errors = Dict.empty
        }
    , Api.websocketDisconnectAll
    )



-- UPDATE


type Msg
    = UpdateNewInviteEmail Email
    | SubmittedNewInvite
    | GotNewInvite (Result (Http.Detailed.Error String) ( Http.Metadata, InstructorInvite ))
    | Logout


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        UpdateNewInviteEmail email ->
            ( updateNewInviteEmail (SafeModel model) email, Cmd.none )

        SubmittedNewInvite ->
            ( SafeModel model
            , case model.newInviteEmail of
                Just email ->
                    postNewInvite model.session
                        model.config
                        email

                Nothing ->
                    Cmd.none
            )

        GotNewInvite (Ok ( metdata, invite )) ->
            ( SafeModel { model | profile = InstructorProfile.addInvite model.profile invite }, Cmd.none )

        GotNewInvite (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errors = errorBodyToDict body }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel
                        { model
                            | errors =
                                Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]
                        }
                    , Cmd.none
                    )

        Logout ->
            ( SafeModel model, Api.logout () )


updateNewInviteEmail : SafeModel -> Email -> SafeModel
updateNewInviteEmail (SafeModel model) email =
    let
        validationErrors =
            if InstructorInvite.isValidEmail email || InstructorInvite.isEmptyEmail email then
                Dict.remove "invite" model.errors

            else
                Dict.insert "invite" "This e-mail is invalid." model.errors
    in
    SafeModel { model | newInviteEmail = Just email, errors = validationErrors }


postNewInvite :
    Session
    -> Config
    -> Email
    -> Cmd Msg
postNewInvite session config email =
    if InstructorInvite.isValidEmail email then
        Api.postDetailed
            (Endpoint.inviteInstructor (Config.restApiUrl config))
            (Session.cred session)
            (Http.jsonBody (inviteEncoder email))
            GotNewInvite
            newInviteResponseDecoder

    else
        Cmd.none


errorBodyToDict : String -> Dict String String
errorBodyToDict body =
    case Decode.decodeString (Decode.dict Decode.string) body of
        Ok dict ->
            dict

        Err err ->
            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]



-- SERIALIZATION


inviteEncoder : Email -> Value
inviteEncoder email =
    Encode.object
        [ ( "email", Encode.string (InstructorInvite.emailToString email) )
        ]


newInviteResponseDecoder : Decoder InstructorInvite.InstructorInvite
newInviteResponseDecoder =
    Decode.map3 InstructorInvite.InstructorInvite
        (Decode.field "email" (Decode.map InstructorInvite.Email Decode.string))
        (Decode.field "invite_code" (Decode.map InstructorInvite.InviteCode Decode.string))
        -- (Decode.field "expiration" (Decode.map InstructorInvite.InviteExpiration Decode.string))
        (Decode.field "expiration" (Decode.map InstructorInvite.InviteExpiration Iso8601.decoder))



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Content Creator Profile"
    , body =
        [ div []
            [ viewContent (SafeModel model)
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ classList [ ( "instructor-profile-items", True ) ] ] <|
            [ div [ class "profile_item" ] <|
                [ span [ class "profile_item_title" ] [ Html.text "Username" ]
                , span [ class "profile_item_value" ]
                    [ Html.text (InstructorProfile.usernameToString (InstructorProfile.username model.profile))
                    ]
                ]
            ]
                ++ viewInstructorInvites (SafeModel model)
                ++ [ div [ class "instructor-profile-texts" ]
                        [ span [ class "profile_item_title" ] [ Html.text "Texts" ]
                        , span [ class "profile_item_value" ] [ viewTexts (SafeModel model) ]
                        ]
                   ]
        ]


viewTexts : SafeModel -> Html Msg
viewTexts (SafeModel model) =
    div [] (List.map (\text -> viewText model.profile text) (InstructorProfile.texts model.profile))


viewText : InstructorProfile -> InstructorProfile.Text -> Html Msg
viewText instructorProfile text =
    let
        instructorUsername =
            InstructorProfile.usernameToString (InstructorProfile.username instructorProfile)
    in
    div [ class "instructor-profile-text" ]
        [ div [ class "text_label" ] [ Html.text "Title" ]
        , div [ class "text_value" ] [ Html.text text.title ]
        , div [ class "text_label" ] [ Html.text "Difficulty" ]
        , div [ class "text_value" ] [ Html.text text.difficulty ]
        , div [ class "text_label" ] [ Html.text "Sections" ]
        , div [ class "text_value" ] [ Html.text (String.fromInt text.text_section_count) ]
        , div [ class "text_label" ] [ Html.text "Created/Modified" ]
        , div [ class "text_value" ]
            [ if text.created_by == instructorUsername then
                div [] [ Html.text "Created by you" ]

              else
                div [] [ Html.text "Last modified by you on ", div [] [ Html.text text.modified_dt ] ]
            ]
        , div [ class "text_label" ] [ Html.text "Tags" ]
        , div [ class "text_value" ] (viewTags text.tags)
        , div [ class "text_label" ]
            [ Html.a
                [ attribute "href" (Route.toString (Route.Text__Edit__Id_Int { id = text.id })) ]
                [ Html.text "Edit Text" ]
            ]
        , div [] []
        ]


viewTags : List InstructorProfile.Tag -> List (Html Msg)
viewTags tags =
    List.map (\tag -> div [] [ Html.text tag ]) tags


viewInstructorInvites : SafeModel -> List (Html Msg)
viewInstructorInvites (SafeModel model) =
    if InstructorProfile.isAdmin model.profile then
        let
            invites =
                Maybe.withDefault [] (InstructorProfile.invites model.profile)
        in
        [ div [ class "profile_item invites" ]
            [ span [ class "profile_item_title" ] [ Html.text "Invitations" ]
            , span [ class "profile_item_value" ]
                [ div [ class "list" ] <|
                    [ viewInstructorInviteMsg (SafeModel model) ]
                        ++ List.map (viewInstructorInvite model.timezone) invites
                        ++ [ viewInstructorInviteCreate (SafeModel model) ]
                ]
            ]
        ]

    else
        []


viewInstructorInvite : Zone -> InstructorInvite -> Html Msg
viewInstructorInvite timezone invite =
    div [ class "invite" ]
        [ div [ class "label" ] [ Html.text "Email: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.emailToString (InstructorInvite.email invite)) ]
        , div [ class "label" ] [ Html.text "Invite Code: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.codeToString (InstructorInvite.inviteCode invite)) ]
        , div [ class "label" ] [ Html.text "Expiration: " ]
        , div [ class "value" ]
            [ Html.text <|
                Utils.Date.monthDayYearFormat timezone
                    (InstructorInvite.expirationToPosix
                        (InstructorInvite.inviteExpiration invite)
                    )
            ]
        ]


viewInstructorInviteMsg : SafeModel -> Html Msg
viewInstructorInviteMsg (SafeModel model) =
    div [ id "invite_msg" ]
        [ Html.text
            """
            After creating an invitation, send the new content creator the invite code and ask
            them to sign up at
            """
        , Html.a [ href "https://stepstoadvancedreading.org/signup/content-creator" ]
            [ text "https://stepstoadvancedreading.org/signup/content-creator" ]
        , Html.text
            """ before the expiration
            time. The content creator will not be emailed automatically.
            """
        ]


viewInstructorInviteCreate : SafeModel -> Html Msg
viewInstructorInviteCreate (SafeModel model) =
    let
        hasError =
            Dict.member "invite" model.errors

        errorAttributes =
            if hasError then
                [ attribute "class" "input_error" ]

            else
                []

        errorMessage =
            div [] [ Html.text (Maybe.withDefault "" (Dict.get "invite" model.errors)) ]
    in
    div [ id "create_invite" ]
        [ div [ id "input" ] <|
            [ Html.input
                ([ attribute "size" "25"
                 , onInput (InstructorInvite.Email >> UpdateNewInviteEmail)
                 , attribute "placeholder" "Invite a content editor"
                 ]
                    ++ errorAttributes
                )
                []
            ]
                ++ (if hasError then
                        [ errorMessage ]

                    else
                        []
                   )
        , div [ id "submit" ]
            [ Html.input [ onClick SubmittedNewInvite, attribute "type" "button", attribute "value" "Submit" ] []
            ]
        ]



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared (SafeModel model) =
    ( SafeModel { model | profile = Profile.toInstructorProfile shared.profile }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
