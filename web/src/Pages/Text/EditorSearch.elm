module Pages.Text.EditorSearch exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href)
import Html.Events exposing (onClick)
import Http exposing (..)
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Text.Decode
import Text.Model exposing (TextListItem)
import User.Profile exposing (Profile)
import Utils.Date
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
        { texts : List TextListItem
        , profile : Profile
        , loading : Bool
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { texts = []
        , profile = shared.profile
        , loading = True
        }
    , getTexts shared.session shared.config
    )



-- UPDATE


type Msg
    = GotTexts (Result Http.Error (List TextListItem))
    | Logout


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        GotTexts (Ok texts) ->
            ( SafeModel
                { model
                    | texts = texts
                    , loading = False
                }
            , Cmd.none
            )

        GotTexts (Err err) ->
            ( SafeModel model, Cmd.none )

        Logout ->
            ( SafeModel model, Api.logout () )


getTexts :
    Session
    -> Config
    -> Cmd Msg
getTexts session config =
    Api.get
        (Endpoint.textSearch (Config.restApiUrl config) [])
        (Session.cred session)
        GotTexts
        Text.Decode.textListDecoder



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Editor Search"
    , body =
        [ div []
            [ viewTexts (SafeModel model)
            , viewFooter (SafeModel model)
            ]
        ]
    }


viewTexts : SafeModel -> Html Msg
viewTexts (SafeModel model) =
    div [ classList [ ( "text_items", True ) ] ]
        (List.map viewText model.texts)


viewText : TextListItem -> Html Msg
viewText textListItem =
    div [ classList [ ( "text_item", True ) ] ]
        [ div [ classList [ ( "item_property", True ) ], attribute "data-id" (String.fromInt textListItem.id) ] [ Html.text "" ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.a [ attribute "href" ("/text/edit/" ++ String.fromInt textListItem.id) ] [ Html.text textListItem.title ]
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text <| "Modified:   " ++ Utils.Date.monthDayYearFormat textListItem.modified_dt
                ]
            ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text <| String.fromInt textListItem.text_section_count
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text "Text Sections"
                ]
            ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text "1"
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text "Languages"
                ]
            ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text textListItem.author
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text "Author"
                ]
            ]
        , viewTags textListItem
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text textListItem.created_by
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text ("Created By (" ++ Utils.Date.monthDayYearFormat textListItem.created_dt ++ ")")
                ]
            ]
        ]


viewTags : TextListItem -> Html Msg
viewTags textListItem =
    div [ classList [ ( "item_property", True ) ] ]
        [ span [ attribute "class" "tag" ]
            [ Html.text
                (case textListItem.tags of
                    Just tags ->
                        String.join ", " tags

                    Nothing ->
                        ""
                )
            ]
        , span [ classList [ ( "sub_description", True ) ] ]
            [ Html.text "Tags"
            ]
        ]


viewFooter : SafeModel -> Html Msg
viewFooter (SafeModel model) =
    div [ classList [ ( "footer_items", True ) ] ]
        [ div [ classList [ ( "footer", True ), ( "message", True ) ] ]
            [ if model.loading then
                Html.text "Loading..."

              else
                Html.text <| "Showing " ++ String.fromInt (List.length model.texts) ++ " entries"
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
