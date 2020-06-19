module Admin exposing (Filter, Flags, Model, Msg(..), init, main, month_day_year_fmt, subscriptions, update, updateTexts, view, view_footer, view_tags, view_text, view_texts)

import Admin.Text
import Date exposing (..)
import Html exposing (..)
import Html.Attributes exposing (attribute, classList)
import Http exposing (..)
import Menu.Items
import Menu.Logout
import Menu.Msg as MenuMsg
import Ports
import Profile.Flags as Flags
import Text.Decode
import Text.Model exposing (TextListItem)
import User.Profile
import Views



-- UPDATE


type Msg
    = Update (Result Http.Error (List TextListItem))
    | LogOut MenuMsg.Msg
    | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)


type alias Flags =
    Flags.Flags
        { text_api_endpoint_url : String
        }


type alias Model =
    { texts : List TextListItem
    , text_api_endpoint : Admin.Text.TextAPIEndpoint
    , profile : User.Profile.Profile
    , menu_items : Menu.Items.MenuItems
    , flags : Flags
    , loading : Bool
    }


type alias Filter =
    List String


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        text_api_endpoint =
            Admin.Text.TextAPIEndpoint (Admin.Text.URL flags.text_api_endpoint_url)
    in
    ( { texts = []
      , text_api_endpoint = text_api_endpoint
      , profile = User.Profile.initProfile flags
      , menu_items = Menu.Items.initMenuItems flags
      , flags = flags
      , loading = True
      }
    , updateTexts text_api_endpoint []
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


updateTexts : Admin.Text.TextAPIEndpoint -> Filter -> Cmd Msg
updateTexts text_api_endpoint filter =
    let
        text_api_endpoint_url =
            Admin.Text.textEndpointToString text_api_endpoint

        request =
            Http.get text_api_endpoint_url Text.Decode.textListDecoder
    in
    Http.send Update request


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Update (Ok texts) ->
            ( { model | texts = texts, loading = False }, Cmd.none )

        -- handle user-friendly msgs
        Update (Err err) ->
            let
                _ =
                    Debug.log "error" err
            in
            ( model, Cmd.none )

        LogOut msg ->
            ( model, User.Profile.logout model.profile model.flags.csrftoken LoggedOut )

        LoggedOut (Ok logout_resp) ->
            ( model, Ports.redirect logout_resp.redirect )

        LoggedOut (Err err) ->
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


month_day_year_fmt : Date -> String
month_day_year_fmt date =
    List.foldr (++)
        ""
        [ (toString <| Date.month date) ++ " ", (toString <| Date.day date) ++ "," ++ " ", toString <| Date.year date ]


view_text : TextListItem -> Html Msg
view_text text_list_item =
    div [ classList [ ( "text_item", True ) ] ]
        [ div [ classList [ ( "item_property", True ) ], attribute "data-id" (toString text_list_item.id) ] [ Html.text "" ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.a [ attribute "href" ("/admin/text/" ++ toString text_list_item.id) ] [ Html.text text_list_item.title ]
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text <| "Modified:   " ++ month_day_year_fmt text_list_item.modified_dt
                ]
            ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text <| toString text_list_item.text_section_count
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
            [ Html.text text_list_item.author
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text "Author"
                ]
            ]
        , view_tags text_list_item
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text text_list_item.created_by
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text ("Created By (" ++ month_day_year_fmt text_list_item.created_dt ++ ")")
                ]
            ]
        ]


view_tags : TextListItem -> Html Msg
view_tags text_list_item =
    div [ classList [ ( "item_property", True ) ] ]
        [ span [ attribute "class" "tag" ]
            [ Html.text
                (case text_list_item.tags of
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


view_texts : Model -> Html Msg
view_texts model =
    div [ classList [ ( "text_items", True ) ] ] (List.map view_text model.texts)


view_footer : Model -> Html Msg
view_footer model =
    div [ classList [ ( "footer_items", True ) ] ]
        [ div [ classList [ ( "footer", True ), ( "message", True ) ] ]
            [ case model.loading of
                True ->
                    Html.text "Loading..."

                False ->
                    Html.text <| "Showing " ++ toString (List.length model.texts) ++ " entries"
            ]
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Views.view_authed_header model.profile model.menu_items LogOut
        , view_texts model
        , view_footer model
        ]
