module Pages.Profile.Instructor exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import User.Instructor.Invite as InstructorInvite exposing (Email, InstructorInvite)
import User.Instructor.Profile as InstructorProfile
    exposing
        ( InstructorProfile(..)
        , InstructorUsername(..)
        )
import User.Instructor.Resource as InstructorResource
import User.Profile as Profile
import Views


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
        , profile : InstructorProfile
        , newInviteEmail : Maybe InstructorInvite.Email
        , errors : Dict String String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , profile = Profile.toInstructorProfile shared.profile
        , newInviteEmail = Nothing
        , errors = Dict.empty
        }
    , Cmd.none
    )



-- UPDATE


type Msg
    = UpdateNewInviteEmail Email
    | SubmittedNewInvite
    | GotNewInvite (Result Http.Error InstructorInvite)
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
                    submitNewInvite model.session
                        model.config
                        email

                Nothing ->
                    Cmd.none
            )

        GotNewInvite (Ok invite) ->
            ( SafeModel { model | profile = InstructorProfile.addInvite model.profile invite }, Cmd.none )

        GotNewInvite (Err err) ->
            ( SafeModel { model | errors = Dict.insert "invite" "Something went wrong." model.errors }, Cmd.none )

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


submitNewInvite :
    Session
    -> Config
    -> Email
    -> Cmd Msg
submitNewInvite session config email =
    if InstructorInvite.isValidEmail email then
        Api.post
            (Endpoint.inviteInstructor (Config.restApiUrl config))
            (Session.cred session)
            (Http.jsonBody (inviteEncoder email))
            GotNewInvite
            newInviteResponseDecoder

    else
        Cmd.none



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
        (Decode.field "expiration" (Decode.map InstructorInvite.InviteExpiration Decode.string))



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Instructor Profile"
    , body =
        [ div []
            [ viewContent (SafeModel model)
            , Views.view_footer
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
                    List.map viewInstructorInvite invites
                        ++ [ viewInstructorInviteCreate (SafeModel model) ]
                ]
            ]
        ]

    else
        []


viewInstructorInvite : InstructorInvite -> Html Msg
viewInstructorInvite invite =
    div [ class "invite" ]
        [ div [ class "label" ] [ Html.text "Email: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.emailToString (InstructorInvite.email invite)) ]
        , div [ class "label" ] [ Html.text "Invite Code: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.codeToString (InstructorInvite.inviteCode invite)) ]
        , div [ class "label" ] [ Html.text "Expiration: " ]
        , div [ class "value" ] [ Html.text (InstructorInvite.expirationToString (InstructorInvite.inviteExpiration invite)) ]
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
                 , attribute "placeholder" "Invite an instructor"
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
