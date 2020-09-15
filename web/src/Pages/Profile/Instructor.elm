module Pages.Profile.Instructor exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode
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



-- type alias Flags =
--     Flags.AuthedFlags
--         { instructor_invite_uri : String
--         , instructorProfile : InstructorProfile.InstructorProfileParams
--         }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , profile = fakeProfile
        , newInviteEmail = Nothing
        , errors = Dict.empty
        }
    , Cmd.none
    )


fakeProfile : InstructorProfile
fakeProfile =
    InstructorProfile
        (Just 0)
        []
        True
        (Just [])
        (InstructorProfile.InstructorUsername "fakeInstructor")
        (InstructorProfile.initProfileURIs
            { logout_uri = "fakeLogoutURI"
            , profile_uri = "fakeProfileURI"
            }
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


newInviteResponseDecoder : Json.Decode.Decoder InstructorInvite.InstructorInvite
newInviteResponseDecoder =
    Json.Decode.map3 InstructorInvite.InstructorInvite
        (Json.Decode.field "email" (Json.Decode.map InstructorInvite.Email Json.Decode.string))
        (Json.Decode.field "invite_code" (Json.Decode.map InstructorInvite.InviteCode Json.Decode.string))
        (Json.Decode.field "expiration" (Json.Decode.map InstructorInvite.InviteExpiration Json.Decode.string))



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "ProtectedApplicationTemplate"
    , body =
        [ div []
            [ viewHeader (SafeModel model)
            , viewContent (SafeModel model)
            , Views.view_footer
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
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
                , span [ class "profile_item_value" ] [ viewTexts (SafeModel model) ]
                ]
            ]
                ++ viewInstructorInvites (SafeModel model)
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
    div [ class "text" ]
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
        , div [ class "text_label" ] [ Html.a [ attribute "href" text.edit_uri ] [ Html.text "Edit Text" ] ]
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
        [ div [ class "invites" ]
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



-- VIEW: HEADER


viewHeader : SafeModel -> Html Msg
viewHeader safeModel =
    Views.view_header
        (viewTopHeader safeModel)
        (viewLowerMenu safeModel)


viewTopHeader : SafeModel -> List (Html Msg)
viewTopHeader safeModel =
    [ div [ classList [ ( "menu_item", True ) ] ]
        [ a
            [ class "link"
            , href
                (Route.toString Route.Profile__Instructor)
            ]
            [ text "Profile" ]
        ]
    , div [ classList [ ( "menu_item", True ) ] ]
        [ a [ class "link", onClick Logout ]
            [ text "Logout" ]
        ]
    ]


viewLowerMenu : SafeModel -> List (Html Msg)
viewLowerMenu (SafeModel model) =
    [ div
        [ classList [ ( "lower-menu-item", True ) ] ]
        [ a
            [ class "link"
            , href (Route.toString Route.NotFound)
            ]
            [ text "Find a text to edit" ]
        ]
    , div
        [ classList
            [ ( "lower-menu-item", True )
            ]
        ]
        [ a
            [ class "link"
            , href (Route.toString Route.Text__Search)
            ]
            [ text "Find a text to read" ]
        ]
    ]



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none
