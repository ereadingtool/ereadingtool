module Admin exposing
    ( Filter
    , Flags
    , Model
    , Msg(..)
    , init
    , main
    , month_day_year_fmt
    , subscriptions
    , update
    , updateTexts
    , view
    , view_footer
    , view_tags
    , view_text
    , view_texts
    )

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
        textApiEndpoint =
            Admin.Text.TextAPIEndpoint (Admin.Text.URL flags.text_api_endpoint_url)
    in
    ( { texts = []
      , text_api_endpoint = textApiEndpoint
      , profile = User.Profile.initProfile flags
      , menu_items = Menu.Items.initMenuItems flags
      , flags = flags
      , loading = True
      }
    , updateTexts textApiEndpoint []
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


updateTexts : Admin.Text.TextAPIEndpoint -> Filter -> Cmd Msg
updateTexts textApiEndpoint filter =
    let
        textApiEndpointUrl =
            Admin.Text.textEndpointToString textApiEndpoint

        request =
            Http.get textApiEndpointUrl Text.Decode.textListDecoder
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

        LoggedOut (Ok logoutResp) ->
            ( model, Ports.redirect logoutResp.redirect )

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
        [ (toString <| Date.month date) ++ " ", (toString <| Date.day date) ++ "," ++ " ", String.fromInt <| Date.year date ]


view_text : TextListItem -> Html Msg
view_text textListItem =
    div [ classList [ ( "text_item", True ) ] ]
        [ div [ classList [ ( "item_property", True ) ], attribute "data-id" (toString text_list_item.id) ] [ Html.text "" ]
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.a [ attribute "href" ("/admin/text/" ++ String.fromInt textListItem.id) ] [ Html.text textListItem.title ]
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text <| "Modified:   " ++ month_day_year_fmt textListItem.modified_dt
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
            [ Html.text text_list_item.author
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text "Author"
                ]
            ]
        , view_tags text_list_item
        , div [ classList [ ( "item_property", True ) ] ]
            [ Html.text textListItem.created_by
            , span [ classList [ ( "sub_description", True ) ] ]
                [ Html.text ("Created By (" ++ month_day_year_fmt textListItem.created_dt ++ ")")
                ]
            ]
        ]


view_tags : TextListItem -> Html Msg
view_tags textListItem =
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


view_texts : Model -> Html Msg
view_texts model =
    div [ classList [ ( "text_items", True ) ] ] (List.map view_text model.texts)


view_footer : Model -> Html Msg
view_footer model =
    div [ classList [ ( "footer_items", True ) ] ]
        [ div [ classList [ ( "footer", True ), ( "message", True ) ] ]
            [ if model.loading then
                Html.text "Loading..."

              else
                Html.text <| "Showing " ++ String.fromInt (List.length model.texts) ++ " entries"
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
