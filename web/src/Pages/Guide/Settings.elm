module Pages.Guide.Settings exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (alt, class, href, id, src, title)
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
    { title = "Guide | Settings"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Settings" ]
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
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Settings)
                , class "guide-link"
                ]
                [ text "Settings" ]
            ]
        , div [ class "guide-tab" ]
            [ a
                [ href (Route.toString Route.Guide__Progress)
                , class "guide-link"
                ]
                [ text "Progress" ]
            ]
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [] """
**1\\.**
When you log into the STAR app, you land on your profile page. This page lets you control
a number of settings and keep track of your reading progress.

**2\\.**
**Settings: Username, Hints.** 
From the top row of settings, you can turn on and off the Hints. By default the pop-up 
bubble Hints are set to appear for new users. You can turn them off, once you’re familiar 
with the app’s functionality.

**3\\.**
**Preferred Difficulty.** You can adjust the difficulty level of the texts you are reading.
The descriptions of the proficiency levels should help you pick a level best suited to your 
abilities or the next level you want to grow into.

**4\\.**
**Research Consent.**
From time to time there may be research projects associated with this site. The Consent forms 
and details will be posted at another site. This button will let you keep track of whether 
you’ll allow your data (disassociated with your name and other identifiers) to be included in 
a study.
"""


viewFirstSectionImage : Html Msg
viewFirstSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/13.png"
            , alt (viewAltText "13" altTexts)
            , title (viewAltText "13" altTexts)
            ]
            []
        ]


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
        [ ( "13", "Student profile page showing their username and password, opt-in status of hints and research" ) ]
