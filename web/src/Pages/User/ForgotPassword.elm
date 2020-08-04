module Pages.User.ForgotPassword exposing
    ( Model
    , Msg
    , Params
    , init
    , page
    , subscriptions
    , update
    , view
    )

import Api exposing (post)
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Dict exposing (Dict)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Json.Encode as Encode
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.ForgotPassword as ForgotPassword
    exposing
        ( ForgotPassResp
        , UserEmail
        , forgotPassRespDecoder
        )
import Utils exposing (isValidEmail)
import Views


page : Page Params Model Msg
page =
    Page.application
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
    { session : Session
    , config : Config
    , userEmail : UserEmail
    , resp : ForgotPassResp
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , userEmail = ForgotPassword.UserEmail ""
      , resp = ForgotPassword.emptyForgotPassResp
      , errors = Dict.fromList []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Submit
    | Submitted (Result Http.Error ForgotPassResp)
    | UpdateEmail String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateEmail addr ->
            ( { model
                | userEmail = ForgotPassword.UserEmail addr
                , resp = ForgotPassword.emptyForgotPassResp
                , errors =
                    if isValidEmail addr || (addr == "") then
                        Dict.remove "email" model.errors

                    else
                        Dict.insert "email" "This e-mail is invalid" model.errors
              }
            , Cmd.none
            )

        Submit ->
            ( { model | errors = Dict.fromList [] }
            , postForgotPassword model.session model.config model.userEmail
            )

        Submitted (Ok resp) ->
            let
                newErrors =
                    Dict.fromList <| Dict.toList model.errors ++ Dict.toList resp.errors
            in
            ( { model | errors = newErrors, resp = resp }, Cmd.none )

        Submitted (Err error) ->
            case error of
                Http.BadStatus _ ->
                    ( model, Cmd.none )

                Http.BadBody _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


postForgotPassword : Session -> Config -> UserEmail -> Cmd Msg
postForgotPassword session config userEmail =
    let
        encodedLoginParams =
            forgotPasswordEncoder userEmail
    in
    Api.post
        (Endpoint.forgotPassword (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedLoginParams)
        Submitted
        forgotPassRespDecoder


forgotPasswordEncoder : UserEmail -> Encode.Value
forgotPasswordEncoder userEmail =
    Encode.object
        [ ( "email", Encode.string (ForgotPassword.userEmailtoString userEmail) )
        ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Forgot Password"
    , body =
        [ div []
            [ Views.view_unauthed_header
            , viewContent model
            , Views.view_footer
            ]
        ]
    }


viewContent : Model -> Html Msg
viewContent model =
    div [ classList [ ( "login", True ) ] ]
        [ div [ class "login_box" ] <|
            viewEmailInput model
                ++ viewSubmit model
                ++ viewErrors model
        ]


viewEmailInput : Model -> List (Html Msg)
viewEmailInput model =
    let
        errorHTML =
            case Dict.get "email" model.errors of
                Just errMsg ->
                    loginLabel [] (Html.em [] [ Html.text errMsg ])

                Nothing ->
                    Html.text ""

        emailError =
            if Dict.member "email" model.errors then
                [ attribute "class" "input_error" ]

            else
                []
    in
    [ loginLabel [] (span [] [ Html.text "E-mail address:" ])
    , Html.input
        ([ attribute "size" "25"
         , onInput UpdateEmail
         ]
            ++ emailError
        )
        []
    , errorHTML
    , viewResponse model.resp
    ]


viewSubmit : Model -> List (Html Msg)
viewSubmit model =
    let
        hasError =
            Dict.member "email" model.errors

        buttonDisabled =
            if hasError || ForgotPassword.userEmailisEmpty model.userEmail then
                [ class "disabled" ]

            else
                [ onClick Submit, class "cursor" ]
    in
    [ loginLabel (class "button" :: buttonDisabled)
        (div [ class "login_submit" ] [ span [] [ Html.text "Forgot Password" ] ])
    ]


viewErrors : Model -> List (Html Msg)
viewErrors model =
    case Dict.get "all" model.errors of
        Just allErrors ->
            [ loginLabel [] (span [ attribute "class" "errors" ] [ Html.em [] [ Html.text <| allErrors ] ]) ]

        _ ->
            [ span [ attribute "class" "errors" ] [] ]


viewResponse : ForgotPassResp -> Html Msg
viewResponse forgotPasswordResponse =
    if not (String.isEmpty forgotPasswordResponse.body) then
        div [ class "msg" ]
            [ span [] [ Html.text forgotPasswordResponse.body ]
            ]

    else
        Html.text ""


loginLabel : List (Html.Attribute Msg) -> Html Msg -> Html Msg
loginLabel attributes html =
    div (attribute "class" "loginLabel" :: attributes)
        [ html
        ]



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
