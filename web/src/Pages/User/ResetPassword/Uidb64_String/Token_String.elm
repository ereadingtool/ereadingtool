module Pages.User.ResetPassword.Uidb64_String.Token_String exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Answer.Field exposing (attributes)
import Api exposing (post)
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onCheck, onClick, onInput)
import Http exposing (..)
import Json.Encode as Encode
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.ForgotPassword as ForgotPassword
    exposing
        ( PassResetConfirmResp
        , resetPasswordResponseDecoder
        , uidb64
        )
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
    { uidb64 : String
    , token : String
    }


type alias Model =
    { session : Session
    , config : Config
    , navKey : Key
    , uidb64 : String
    , token : String
    , password : String
    , confirmPassword : String
    , showPassword : Bool
    , resp : PassResetConfirmResp
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , navKey = shared.key
      , uidb64 = params.uidb64
      , token = params.token
      , password = ""
      , confirmPassword = ""
      , showPassword = False
      , resp = ForgotPassword.emptyPassResetResp
      , errors = Dict.fromList []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Submit
    | Submitted (Result Http.Error PassResetConfirmResp)
    | UpdatePassword String
    | UpdatePasswordConfirm String
    | ToggleShowPassword Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword _ ->
            ( { model | showPassword = not model.showPassword }, Cmd.none )

        UpdatePassword pass ->
            ( { model
                | password = pass
                , resp = ForgotPassword.emptyPassResetResp
                , errors =
                    Dict.fromList
                        (if pass /= model.confirmPassword then
                            [ ( "all", "Passwords must match" ) ]

                         else
                            []
                        )
              }
            , Cmd.none
            )

        UpdatePasswordConfirm confirmPassword ->
            ( { model
                | confirmPassword = confirmPassword
                , resp = ForgotPassword.emptyPassResetResp
                , errors =
                    Dict.fromList
                        (if confirmPassword /= model.password then
                            [ ( "all", "Passwords must match" ) ]

                         else
                            []
                        )
              }
            , Cmd.none
            )

        Submit ->
            ( { model | errors = Dict.fromList [] }
            , postPasswordReset model.session
                model.config
                (ForgotPassword.Password
                    (ForgotPassword.Password1 model.password)
                    (ForgotPassword.Password2 model.confirmPassword)
                    (ForgotPassword.UIdb64 model.uidb64)
                )
            )

        Submitted (Ok resp) ->
            ( { model | resp = resp }
            , Browser.Navigation.replaceUrl model.navKey resp.redirect
            )

        Submitted (Err error) ->
            case error of
                Http.BadStatus resp ->
                    ( model, Cmd.none )

                Http.BadBody _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


postPasswordReset : Session -> Config -> ForgotPassword.Password -> Cmd Msg
postPasswordReset session config password =
    let
        encodedResetParams =
            resetPasswordEncoder password
    in
    Api.post
        (Endpoint.resetPassword (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedResetParams)
        Submitted
        resetPasswordResponseDecoder


resetPasswordEncoder : ForgotPassword.Password -> Encode.Value
resetPasswordEncoder password =
    Encode.object
        [ ( "new_password1", Encode.string (ForgotPassword.password1toString (ForgotPassword.password1 password)) )
        , ( "new_password2", Encode.string (ForgotPassword.password2toString (ForgotPassword.password2 password)) )
        , ( "uidb64", Encode.string (ForgotPassword.uidb64toString (ForgotPassword.uidb64 password)) )
        ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Reset Password"
    , body =
        [ div []
            [ viewContent model
            , Views.view_footer
            ]
        ]
    }


viewContent : Model -> Html Msg
viewContent model =
    div [ classList [ ( "login", True ) ] ]
        [ div [ class "login_box" ] <|
            viewPasswordInput model
                ++ viewPasswordConfirmInput model
                ++ viewErrors model
                ++ viewShowPasswordToggle model
                ++ viewSubmit model
        ]


viewPasswordInput : Model -> List (Html Msg)
viewPasswordInput model =
    let
        errorHTML =
            case Dict.get "password" model.errors of
                Just err_msg ->
                    validationError (Html.em [] [ Html.text err_msg ])

                Nothing ->
                    Html.text ""

        passwordError =
            if Dict.member "password" model.errors || Dict.member "all" model.errors then
                [ attribute "class" "input_error" ]

            else
                []

        showPassword =
            if model.showPassword then
                []

            else
                [ attribute "type" "password" ]
    in
    [ loginLabel [] (span [] [ Html.text "Set a new password" ])
    , Html.input
        ([ attribute "size" "25"
         , onInput UpdatePassword
         ]
            ++ passwordError
            ++ showPassword
        )
        []
    , errorHTML
    , viewResponse model.resp
    ]


viewPasswordConfirmInput : Model -> List (Html Msg)
viewPasswordConfirmInput model =
    let
        errorHTML =
            case Dict.get "confirmPassword" model.errors of
                Just errMsg ->
                    validationError (Html.em [] [ Html.text errMsg ])

                Nothing ->
                    Html.text ""

        passwdError =
            if Dict.member "confirmPassword" model.errors || Dict.member "all" model.errors then
                [ attribute "class" "input_error" ]

            else
                []

        showPassword =
            if model.showPassword then
                []

            else
                [ attribute "type" "password" ]
    in
    [ loginLabel [] (span [] [ Html.text "Confirm Password" ])
    , Html.input
        ([ attribute "size" "25"
         , onInput UpdatePasswordConfirm
         ]
            ++ passwdError
            ++ showPassword
        )
        []
    , errorHTML
    , viewResponse model.resp
    ]


viewResponse : PassResetConfirmResp -> Html Msg
viewResponse resetPasswordResponse =
    if not (String.isEmpty resetPasswordResponse.body) then
        div [ class "msg" ]
            [ span [] [ Html.text resetPasswordResponse.body ]
            ]

    else
        Html.text ""


viewErrors : Model -> List (Html Msg)
viewErrors model =
    List.map
        (\( k, v ) ->
            validationError (span [ attribute "class" "errors" ] [ Html.em [] [ Html.text v ] ])
        )
        (Dict.toList model.errors)


viewShowPasswordToggle : Model -> List (Html Msg)
viewShowPasswordToggle model =
    [ div [ class "password-reset-show" ]
        [ Html.input
            ([ attribute "type" "checkbox", onCheck ToggleShowPassword ]
                ++ (if model.showPassword then
                        [ attribute "checked" "true" ]

                    else
                        []
                   )
            )
            []
        , Html.label [ class "show-password-label" ] [ Html.text "Show Password" ]
        ]
    ]


viewSubmit : Model -> List (Html Msg)
viewSubmit model =
    let
        hasError =
            Dict.member "password" model.errors || Dict.member "confirmPassword" model.errors

        emptyPasswords =
            String.isEmpty model.password && String.isEmpty model.confirmPassword

        passwordsMatch =
            model.password == model.confirmPassword

        buttonDisabled =
            if hasError || emptyPasswords || not passwordsMatch then
                [ class "disabled" ]

            else
                [ onClick Submit, class "cursor" ]
    in
    if hasError || emptyPasswords || not passwordsMatch then
        [ div
            [ classList
                [ ( "button", True )
                , ( "disabled", True )
                ]
            ]
            [ div [ class "login_submit" ] [ span [] [ Html.text "Change Password" ] ] ]
        ]

    else
        [ div
            [ classList
                [ ( "button", True )
                , ( "cursor", True )
                ]
            , onClick Submit
            ]
            [ div [ class "login_submit" ] [ span [] [ Html.text "Change Password" ] ] ]
        ]


loginLabel : List (Html.Attribute Msg) -> Html Msg -> Html Msg
loginLabel attributes html =
    div (attribute "class" "login_label" :: attributes)
        [ html
        ]


validationError : Html msg -> Html msg
validationError html =
    div [ class "validation-error" ]
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
