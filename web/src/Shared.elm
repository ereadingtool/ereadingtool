module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Api
import Api.Config as Config exposing (Config)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Session exposing (Session)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Url exposing (Url)
import Viewer exposing (Viewer)



-- INIT


type alias Flags =
    { maybeConfig : Maybe Config
    , maybeViewer : Maybe Viewer
    }


type alias Model =
    { url : Url
    , key : Key
    , session : Session
    , config : Config
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        session =
            Session.fromViewer flags.maybeViewer

        config =
            Config.init flags.maybeConfig
    in
    ( Model url key session config
    , Cmd.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
    { title = page.title
    , body =
        [ div [ class "layout" ]
            [ header [ class "navbar" ]
                [ a [ class "link", href (Route.toString Route.Top) ] [ text "Homepage" ]
                , a [ class "link", href (Route.toString Route.NotFound) ] [ text "Not found" ]
                , a [ class "link", href (Route.toString Route.About) ] [ text "About" ]
                , a [ class "link", href (Route.toString Route.Acknowledgments) ] [ text "Acknowledgments" ]
                , div []
                    [ text ("Token: " ++ Api.exposeToken (Session.cred model.session)) ]
                , div [] [ text ("REST API URL: " ++ Config.restApiUrl model.config) ]
                ]
            , div [ class "page" ] page.body
            ]
        ]
    }
