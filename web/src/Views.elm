module Views exposing
    ( view_authed_header
    , view_footer
    , view_header
    , view_unauthed_header
    )

import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, id)
import Menu.Items
import Menu.Msg
import Menu.View
import User.Profile exposing (Profile)


view_logo : List (Html.Attribute msg) -> Html msg
view_logo event_attr =
    Html.img
        ([ attribute "src" "/public/img/star_logo.png"
         , id "logo"
         , attribute "alt" "Steps To Advanced Reading Logo"
         ]
            ++ event_attr
        )
        []


view_header : List (Html msg) -> List (Html msg) -> Html msg
view_header top_menu_items bottom_menu_items =
    div []
        [ div [ id "header" ]
            [ view_logo []
            , div [ class "menu" ] top_menu_items
            ]
        , div [ id "lower-menu" ]
            [ div [ id "lower-menu-items" ] bottom_menu_items
            ]
        ]


view_unauthed_header : Html msg
view_unauthed_header =
    view_header [] []


view_authed_header : Profile -> Menu.Items.MenuItems -> (Menu.Msg.Msg -> msg) -> Html msg
view_authed_header profile menu_items top_level_menu_msg =
    view_header
        (Menu.View.view_top_menu menu_items profile top_level_menu_msg)
        (Menu.View.view_lower_menu menu_items profile top_level_menu_msg)



-- view_give_feedback : Html msg
-- view_give_feedback =
--     div []
--         [ Html.a [ attribute "href" "https://goo.gl/forms/z5BKx36xBJR7XqQY2" ]
--             [ Html.text "Please give us feedback!"
--             ]
--         ]
-- view_report_problem : Html msg
-- view_report_problem =
--     div []
--         [ Html.a [ attribute "href" "https://goo.gl/forms/Wn5wWVHdmBKOxsFt2" ]
--             [ Html.text "Report a problem"
--             ]
--         ]


view_footer : Html msg
view_footer =
    div [ classList [ ( "footer_items", True ) ] ]
        [ div [ classList [ ( "footer", True ), ( "message", True ) ] ] []
        ]


view_preview : Html msg
view_preview =
    div [ classList [ ( "preview", True ) ] ]
        [ div [ classList [ ( "preview_menu", True ) ] ]
            [ span [ classList [ ( "menu_item", True ) ] ]
                [ Html.input [ attribute "placeholder" "Search texts.." ] []
                ]
            ]
        ]
