module Pages.User.ForgotPassword exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Api exposing (post)
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Dict exposing (Dict)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Http.Detailed
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Ports
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
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


type alias ForgotPasswordResponse =
    { errors : Dict String String
    , body : String
    }



-- INIT


type alias Params =
    ()


type alias Model =
    { session : Session
    , config : Config
    , email : String
    , response : ForgotPasswordResponse
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , email = ""
      , response =
            { errors = Dict.empty
            , body = ""
            }
      , errors = Dict.fromList []
      }
    , Ports.clearInputText "email-input"
    )



-- UPDATE


type Msg
    = Submit
    | Submitted (Result (Http.Detailed.Error String) ( Http.Metadata, ForgotPasswordResponse ))
    | UpdateEmail String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateEmail email ->
            ( { model
                | email = email
                , response =
                    { errors = Dict.empty
                    , body = ""
                    }
                , errors =
                    if isValidEmail email || String.isEmpty email then
                        Dict.remove "email" model.errors

                    else
                        Dict.insert "email" "This e-mail is invalid" model.errors
              }
            , Cmd.none
            )

        Submit ->
            ( { model | errors = Dict.fromList [] }
            , postForgotPassword model.session model.config model.email
            )

        Submitted (Ok ( metadata, response )) ->
            let
                errors =
                    Dict.fromList <| Dict.toList model.errors ++ Dict.toList response.errors
            in
            ( { model | errors = errors, response = response }, Cmd.none )

        Submitted (Err error) ->
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


postForgotPassword : Session -> Config -> String -> Cmd Msg
postForgotPassword session config userEmail =
    let
        encodedLoginParams =
            forgotPasswordEncoder userEmail
    in
    Api.postDetailed
        (Endpoint.forgotPassword (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedLoginParams)
        Submitted
        forgotPassRespDecoder


forgotPasswordEncoder : String -> Encode.Value
forgotPasswordEncoder email =
    Encode.object
        [ ( "email", Encode.string email )
        ]


forgotPassRespDecoder : Decoder ForgotPasswordResponse
forgotPassRespDecoder =
    Decode.succeed ForgotPasswordResponse
        |> required "errors" (Decode.dict Decode.string)
        |> required "body" Decode.string


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
    { title = "Forgot Password"
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
            viewEmailInput model
                ++ viewSubmit model
                ++ viewErrors model
        ]


viewEmailInput : Model -> List (Html Msg)
viewEmailInput model =
    let
        errorMessage =
            case Dict.get "email" model.errors of
                Just error ->
                    validationError (Html.em [] [ Html.text error ])

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
        ([ id "email-input"
         , attribute "size" "25"
         , onInput UpdateEmail
         ]
            ++ emailError
        )
        []
    , errorMessage
    , viewResponse model.response
    ]


viewSubmit : Model -> List (Html Msg)
viewSubmit model =
    let
        buttonDisabled =
            if Dict.member "email" model.errors || String.isEmpty model.email then
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
        Just errors ->
            [ loginLabel [] (span [ attribute "class" "errors" ] [ Html.em [] [ Html.text <| errors ] ]) ]

        _ ->
            [ span [ attribute "class" "errors" ] [] ]


viewResponse : ForgotPasswordResponse -> Html Msg
viewResponse forgotPasswordResponse =
    if not (String.isEmpty forgotPasswordResponse.body) then
        div [ class "password-reset-msg" ]
            [ span [] [ Html.text forgotPasswordResponse.body ]
            ]

    else
        Html.text ""


loginLabel : List (Html.Attribute Msg) -> Html Msg -> Html Msg
loginLabel attributes html =
    div (attribute "class" "login_label" :: attributes)
        [ html
        ]


validationError : Html Msg -> Html Msg
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
