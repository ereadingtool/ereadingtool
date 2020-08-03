module Pages.User.PasswordReset.Top exposing (Flags, Model, Msg(..), flagsToForgotPassURI, forgot_pass_encoder, init, login_label, main, post_forgot_pass, subscriptions, update, view, view_content, view_email_input, view_errors, view_resp, view_submit)

import Dict exposing (Dict)
import Flags
import User.ForgotPassword exposing (ForgotPassResp, ForgotPassURI, UserEmail, forgotPassRespDecoder)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Utils.HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Json.Encode as Encode
import Utils exposing (isValidEmail)

import Browser
import Views


type alias Flags =
    Flags.UnAuthedFlags { forgot_pass_endpoint : String }


type Msg
    = Submit
    | Submitted (Result Http.Error ForgotPassResp)
    | UpdateEmail String


type alias Model =
    { flags : Flags
    , user_email : UserEmail
    , forgot_pass_uri : User.ForgotPassword.ForgotPassURI
    , resp : ForgotPassResp
    , errors : Dict String String
    }


flagsToForgotPassURI : { a | forgot_pass_endpoint : String } -> ForgotPassURI
flagsToForgotPassURI flags =
    User.ForgotPassword.ForgotPassURI (User.ForgotPassword.URI flags.forgot_pass_endpoint)


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { flags = flags
      , user_email = User.ForgotPassword.UserEmail ""
      , forgot_pass_uri = flagsToForgotPassURI flags
      , resp = User.ForgotPassword.emptyForgotPassResp
      , errors = Dict.fromList []
      }
    , Cmd.none
    )


forgot_pass_encoder : UserEmail -> Encode.Value
forgot_pass_encoder user_email =
    Encode.object
        [ ( "email", Encode.string (User.ForgotPassword.userEmailtoString user_email) )
        ]


post_forgot_pass : ForgotPassURI -> Flags.CSRFToken -> UserEmail -> Cmd Msg
post_forgot_pass forgot_pass_endpoint csrftoken user_email =
    let
        encoded_login_params =
            forgot_pass_encoder user_email

        req =
            post_with_headers
                (User.ForgotPassword.uriToString (User.ForgotPassword.forgotPassURI forgot_pass_endpoint))
                [ Http.header "X-CSRFToken" csrftoken ]
                (Http.jsonBody encoded_login_params)
                forgotPassRespDecoder
    in
    Http.send Submitted req


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateEmail addr ->
            ( { model
                | user_email = User.ForgotPassword.UserEmail addr
                , resp = User.ForgotPassword.emptyForgotPassResp
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
            , post_forgot_pass model.forgot_pass_uri model.flags.csrftoken model.user_email
            )

        Submitted (Ok resp) ->
            let
                new_errors =
                    Dict.fromList <| Dict.toList model.errors ++ Dict.toList resp.errors
            in
            ( { model | errors = new_errors, resp = resp }, Cmd.none )

        Submitted (Err error) ->
            case error of
                Http.BadStatus resp ->
                    case Decode.decodeString (Decode.dict Decode.string) resp.body of
                        Ok errors ->
                            ( { model | errors = errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


login_label : List (Html.Attribute Msg) -> Html Msg -> Html Msg
login_label attributes html =
    div ([ attribute "class" "login_label" ] ++ attributes)
        [ html
        ]


view_errors : Model -> List (Html Msg)
view_errors model =
    case Dict.get "all" model.errors of
        Just all_err ->
            [ login_label [] (span [ attribute "class" "errors" ] [ Html.em [] [ Html.text <| all_err ] ]) ]

        _ ->
            [ span [ attribute "class" "errors" ] [] ]


view_submit : Model -> List (Html Msg)
view_submit model =
    let
        has_error =
            Dict.member "email" model.errors

        button_disabled =
            if has_error || User.ForgotPassword.userEmailisEmpty model.user_email then
                [ class "disabled" ]

            else
                [ onClick Submit, class "cursor" ]
    in
    [ login_label ([ class "button" ] ++ button_disabled)
        (div [ class "login_submit" ] [ span [] [ Html.text "Forgot Password" ] ])
    ]


view_resp : ForgotPassResp -> Html Msg
view_resp forgot_pass_resp =
    if not (String.isEmpty forgot_pass_resp.body) then
        div [ class "msg" ]
            [ span [] [ Html.text forgot_pass_resp.body ]
            ]

    else
        Html.text ""


view_email_input : Model -> List (Html Msg)
view_email_input model =
    let
        errorHTML =
            case Dict.get "email" model.errors of
                Just err_msg ->
                    login_label [] (Html.em [] [ Html.text err_msg ])

                Nothing ->
                    Html.text ""

        email_error =
            if Dict.member "email" model.errors then
                [ attribute "class" "input_error" ]

            else
                []
    in
    [ login_label [] (span [] [ Html.text "E-mail address:" ])
    , Html.input
        ([ attribute "size" "25"
         , onInput UpdateEmail
         ]
            ++ email_error
        )
        []
    , errorHTML
    , view_resp model.resp
    ]


view_content : Model -> Html Msg
view_content model =
    div [ classList [ ( "login", True ) ] ]
        [ div [ class "login_box" ] <|
            view_email_input model
                ++ view_submit model
                ++ view_errors model
        ]


view : Model -> Html Msg
view model =
    div []
        [ Views.view_unauthed_header
        , view_content model
        , Views.view_footer
        ]
