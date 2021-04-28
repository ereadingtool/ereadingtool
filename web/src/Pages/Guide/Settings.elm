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
    div [ class "guide-image-container"] 
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
        [ ( "1", "Screenshot of login page" )
        , ( "2", "Screenshot of profile page with difficulty level options" )
        , ( "3", "Screenshot of student performance table" )
        , ( "4", "Screenshot of search filter for text difficulty level" )
        , ( "5", "Screenshot of search filter for text topics" )
        , ( "6", "Screenshot of search filter for text read status" )
        , ( "7"
          , "Screenshot of text pre-reading screen, with a brief description of the text and a Start button"
          )
        , ( "8", "Screenshot of one section of a text" )
        , ( "9", "Screenshot of a text with a word glossed" )
        , ( "10", "Screenshot of a multiple-choice comprehension question" )
        , ( "11-left", "Screenshot of a text comprehension question answered correctly with feedback" )
        , ( "11-right", "Screenshot of a text comprehension question answered incorrectly with feedback" )
        , ( "12"
          , "Screenshot of post-reading page with number of questions answered correctly, "
                ++ "a message directing students to the Search Texts page, and a link to a reading related "
                ++ "to the text"
          )
        , ( "13"
          , "Screenshot of the two mode options for flashcards, which are “Review Only” mode and "
                ++ "“Review and Answer” mode"
          )
        , ( "14-left"
          , "Screenshot of the front of a flashcard in “Review only” mode, with the Russian word "
                ++ "and its context"
          )
        , ( "14-right"
          , "Screenshot of the back of a flashcard in “Review only” mode, with the English "
                ++ "translation of the Russian word, and the word’s context"
          )
        , ( "15-left"
          , "Screenshot of the front of a flashcard in “Review and Answer” mode, with the Russian "
                ++ "word, the word’s context, and a box where students type the answer"
          )
        , ( "15-right"
          , "Screenshot of the back of a flashcard in “Review and Answer” mode, with the English "
                ++ "translation of the Russian word, the word’s context, and six options from 0 to 5 "
                ++ "(0 being the most difficult, 5 being the easiest) so that students can judge how "
                ++ "difficult they found the word"
          )
        ]