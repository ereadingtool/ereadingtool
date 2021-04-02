module Pages.Guide.Progress exposing (..)

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
    { title = "Guide | Progress"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Progress" ]
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
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Progress)
                , class "guide-link"
                ]
                [ text "Progress" ]
            ]
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [ attribute "class" "markdown-link" ] """
**1\\.**
**My Words.** In this section, you can access the words that you have saved from when you 
were reading texts and looking up words. You can download these words either as a PDF 
(to review visually), or as a plain comma-separated text file, which you can paste in a 
flashcards program like [Quizlet](https://quizlet.com/), [Anki](https://apps.ankiweb.net/),
or [Kommit](https://kommit.rosano.ca/). For each word you’ve saved, you’ll get the dictionary 
form of the word, part of the text’s sentence that includes the word from the text you were 
reading and an English equivalent appropriate for that context.

**2\\.**
**My Performance.** 
This section gives you two tables: the “Completion” table shows you how much you’ve been 
reading, by proficiency levels, over the current month (today and the previous 30 days), 
the previous month (31 to 60 days ago), and cumulatively. The “First Time Comprehension” 
table will show you how many comprehension questions you’ve answered correctly the first 
time that you tried them, and what % that represents from all the questions you’ve tried 
at that level.
"""


viewFirstSectionImage : Html Msg
viewFirstSectionImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/13.png"
            , alt (viewAltText "13" altTexts)
            , title (viewAltText "13" altTexts)
            ] 
            [] 
        ]


viewSecondSection : Html Msg
viewSecondSection =
    Markdown.toHtml [] """
**3\\.**
This “first time correct” number is a good indicator of how well you will probably read in a 
testing situation.


You can download the “My Performance” tables as a PDF document if you want or need to share 
your progress with a teacher or an advisor.


**4\\.**
**Contact.**
These links allow you to report any problems that you encounter when using the site, or to 
give a general evaluation of the site, its layout and functionality.
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