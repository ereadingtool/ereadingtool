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
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onCheck, onClick, onInput)
import Http exposing (..)
import Http.Detailed
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
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


type alias PasswordResetParams =
    { password : String
    , confirmPassword : String
    , uidb64 : String
    , token : String
    }


type alias PasswordResetResponse =
    { errors : Dict String String
    , body : String
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
    , response : PasswordResetResponse
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
      , response =
            { errors = Dict.empty
            , body = ""
            }
      , errors = Dict.empty
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ToggleShowPassword Bool
    | UpdatePassword String
    | UpdateConfirmPassword String
    | SubmittedForm
    | GotResetResponse (Result (Http.Detailed.Error String) ( Http.Metadata, PasswordResetResponse ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword _ ->
            ( { model | showPassword = not model.showPassword }, Cmd.none )

        UpdatePassword pass ->
            ( { model
                | password = pass
                , response = emptyResponse
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

        UpdateConfirmPassword confirmPassword ->
            ( { model
                | confirmPassword = confirmPassword
                , response = emptyResponse
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

        SubmittedForm ->
            ( { model | errors = Dict.fromList [] }
            , postPasswordReset model.session
                model.config
                { password = model.password
                , confirmPassword = model.confirmPassword
                , uidb64 = model.uidb64
                , token = model.token
                }
            )

        GotResetResponse (Ok ( metadata, response )) ->
            ( { model | response = response }
            , Browser.Navigation.replaceUrl model.navKey (Route.toString Route.Login__Student)
            )

        GotResetResponse (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    ( { model | errors = errorBodyToDict body }
                    , Cmd.none
                    )

                _ ->
                    ( { model
                        | errors =
                            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]
                      }
                    , Cmd.none
                    )


postPasswordReset : Session -> Config -> PasswordResetParams -> Cmd Msg
postPasswordReset session config passwordResetParams =
    let
        encodedResetParams =
            resetPasswordEncoder passwordResetParams
    in
    Api.postDetailed
        (Endpoint.resetPassword (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedResetParams)
        GotResetResponse
        resetPasswordResponseDecoder


resetPasswordEncoder : PasswordResetParams -> Encode.Value
resetPasswordEncoder { password, confirmPassword, uidb64, token } =
    Encode.object
        [ ( "new_password1", Encode.string password )
        , ( "new_password2", Encode.string confirmPassword )
        , ( "uidb64", Encode.string uidb64 )
        , ( "token", Encode.string token )
        ]


resetPasswordResponseDecoder : Decoder PasswordResetResponse
resetPasswordResponseDecoder =
    Decode.succeed PasswordResetResponse
        |> required "errors" (Decode.dict Decode.string)
        |> required "body" Decode.string


emptyResponse : PasswordResetResponse
emptyResponse =
    { errors = Dict.empty
    , body = ""
    }


errorBodyToDict : String -> Dict String String
errorBodyToDict body =
    case Decode.decodeString (Decode.dict Decode.string) body of
        Ok dict ->
            dict

        Err err ->
            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]



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
        errorMessage =
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
    [ div [ class "login_role" ] [ Html.text "Reset Password" ]
    , div [ class "input-container" ] [
        Html.input
            ([ id "email-input"
            , attribute "size" "25"
            , attribute "placeholder" "New password"
            , onInput UpdatePassword
            ]
                ++ passwordError
                ++ showPassword
            )
            []
        , errorMessage
        , viewResponse model.response
        ]
    ]


viewPasswordConfirmInput : Model -> List (Html Msg)
viewPasswordConfirmInput model =
    let
        errorMessage =
            case Dict.get "confirmPassword" model.errors of
                Just errMsg ->
                    validationError (Html.em [] [ Html.text errMsg ])

                Nothing ->
                    Html.text ""

        passwordError =
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
    [ div [ class "input-container" ] [ 
        Html.input
            ([ id "email-input"
            , attribute "size" "25"
            , attribute "placeholder" "Confirm password"
            , onInput UpdateConfirmPassword
            ]
                ++ passwordError
                ++ showPassword
            )
            []
        , errorMessage
        , viewResponse model.response
        ]
    ]

viewResponse : PasswordResetResponse -> Html Msg
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
    let
        showPasswordChecked =
            if model.showPassword then
                [ attribute "checked" "true" ]

            else
                []
    in
    [ div [ class "password-reset-show" ]
        [ Html.input
            ([ attribute "type" "checkbox", onCheck ToggleShowPassword ]
                ++ showPasswordChecked
            )
            []
        , Html.label [ class "show-password-label" ] [ Html.text "Show Password" ]
        ]
    ]


viewSubmit : Model -> List (Html Msg)
viewSubmit model =
    if
        (Dict.member "password" model.errors || Dict.member "confirmPassword" model.errors)
            || (String.isEmpty model.password || String.isEmpty model.confirmPassword)
            || (model.password /= model.confirmPassword)
    then
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
            , onClick SubmittedForm
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
