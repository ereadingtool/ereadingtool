module Pages.Guide.Context exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, class, href, id, src, style, title)
import Markdown
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)


page : Page Params Model Msg
page =
    Page.static
        { view = view
        }


type alias Model =
    Url Params


type alias Msg =
    Never



-- VIEW


type alias Params =
    ()


view : Url Params -> Document Msg
view { params } =
    { title = "Guide | Context"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Context" ]
                    , viewTabs
                    , viewFirstSection
                    , viewFirstSectionImage
                    ]
                ]
            ]
        ]
    }


viewTabs : Html Msg
viewTabs =
    div [ class "guide-tabs" ]
        [ div
            [ class "guide-tab"
            , class "leftmost-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__GettingStarted)
                , class "guide-link"
                ]
                [ text "Getting Started" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__ReadingTexts)
                , class "guide-link"
                ]
                [ text "Reading Texts" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Settings)
                , class "guide-link"
                ]
                [ text "Settings" ]
            ]
        , div
            [ class "guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Progress)
                , class "guide-link"
                ]
                [ text "Progress" ]
            ]
        , div [ class "guide-tab" 
            ]
            [ a
                [ href (Route.toString Route.Guide__Strategies)
                , class "guide-link"
                ]
                [ text "Strategies" ]
            ]
        , div [ class "guide-tab" 
            ]
            [ a
                [ href (Route.toString Route.Guide__Comprehension)
                , class "guide-link"
                ]
                [ text "Comprehension" ]
            ]
        , div [ class "guide-tab" 
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Context)
                , class "guide-link"
                ]
                [ text "Context" ]
            ]
        , div [ class "guide-tab" 
            ]
            [ a
                [ href (Route.toString Route.Guide__Priority)
                , class "guide-link"
                ]
                [ text "Priority" ]
            ]
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """

"""


viewFirstSectionImage : Html Msg
viewFirstSectionImage =
    div [ class "guide-image-container" ]
        [
        -- [ img
            -- [ class "guide-image"
            -- , src "/public/img/tutorial/student/14.png"
            -- , alt (viewAltText "13" altTexts)
            -- , title (viewAltText "13" altTexts)
            -- ]
            -- []
        ]


viewSecondSection : Html Msg
viewSecondSection =
    Markdown.toHtml [] """

"""


viewAltText : String -> Dict String String -> String
viewAltText id texts =
    case Dict.get id texts of
        Just text ->
            text

        Nothing ->
            ""


altTexts : Dict String String
altTexts =
    Dict.fromList
        [ ]
