module Pages.ProtectedStudentApplication exposing (Model, Msg, Params, page)

import Html exposing (..)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)


page : Page Params Model Msg
page =
    Page.protectedStudentApplication
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
        { protectedInfo : String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { protectedInfo = "Only students can access this page"
        }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        ReplaceMe ->
            ( SafeModel model, Cmd.none )


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "ProtectedApplicationTemplate"
    , body =
        [ div [] [ text model.protectedInfo ]
        ]
    }
