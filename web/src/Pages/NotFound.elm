module Pages.NotFound exposing (Model, Msg, Params, page)

import Html exposing (..)
import Html.Attributes exposing (class, href, src)
import Role exposing (Role(..))
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Viewer


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
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Nop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Nop ->
            ( model, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Not Found"
    , body =
        [ div [ class "not-found" ]
            [ h1 [ class "not-found-giant-heading" ] [ text "404" ]
            , h1 [] [ text "We tried our very best, but we were unable to find that page." ]
            , img [ src "/public/img/404.jpg" ] []
            , case Session.viewer model.session of
                Just viewer ->
                    case Viewer.role viewer of
                        Student ->
                            a [ href (Route.toString Route.Profile__Student) ] [ text "Return to your profile page" ]

                        Instructor ->
                            a [ href (Route.toString Route.Profile__ContentCreator) ] [ text "Return to your profile page" ]

                Nothing ->
                    a [ href (Route.toString Route.Top) ] [ text "Return to homepage" ]
            ]
        ]
    }
