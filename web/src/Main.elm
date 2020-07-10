module Main exposing
    ( Model
    , Msg(..)
    , init
    , main
    , subscriptions
    , update
    , view
    )

import Api
import Browser
import Html exposing (button, div, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Session exposing (Session)
import Viewer exposing (Viewer)



-- MAIN


main =
    Api.application Viewer.decoder
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { session : Session
    , testMessage : String
    }


init : Maybe Viewer -> ( Model, Cmd Msg )
init maybeViewer =
    let
        session =
            Session.fromViewer maybeViewer
    in
    ( { session = session
      , testMessage = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Login
    | Logout
    | SubmittedTest
    | GotSession Session
    | GotTest (Result Http.Error TestMessage)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Login ->
            ( model, login )

        Logout ->
            ( model, logout )

        GotSession session ->
            ( { model
                | session = session
              }
            , Cmd.none
            )

        SubmittedTest ->
            ( model
            , Api.get
                "test"
                (Session.cred model.session)
                GotTest
                testMessageDecoder
            )

        GotTest (Ok testMessage) ->
            ( { model | testMessage = testMessageToString testMessage }, Cmd.none )

        GotTest (Err _) ->
            ( { model | testMessage = "HTTP Request failed" }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        loginStatus =
            case Session.viewer model.session of
                Just _ ->
                    "logged in"

                Nothing ->
                    "logged out"
    in
    { title = "ereadingtool"
    , body =
        [ button [ onClick Login ] [ text "Login" ]
        , button [ onClick Logout ] [ text "Logout" ]
        , div [] [ text ("Status: " ++ loginStatus) ]
        , div []
            [ text ("Token: " ++ Api.exposeToken (Session.cred model.session)) ]
        , button [ onClick SubmittedTest ] [ text "HTTP Test" ]
        , div [] [ text model.testMessage ]
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Session.changes GotSession



-- AUTH


login : Cmd msg
login =
    let
        creds =
            Encode.object
                [ ( "email", Encode.string "test@email.com" )
                , ( "password", Encode.string "password" )
                ]
    in
    Api.login creds


logout : Cmd msg
logout =
    Api.logout ()



-- HTTP TEST


type TestMessage
    = TestMessage String


testMessageDecoder : Decoder TestMessage
testMessageDecoder =
    Decode.succeed TestMessage
        |> required "message" Decode.string


testMessageToString : TestMessage -> String
testMessageToString (TestMessage message) =
    message
