module Pages.Guide.ReadingTexts exposing (Model, Msg, Params, page)

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
    { title = "Guide | Reading Texts"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Reading Texts" ]
                    , viewTabs
                    , viewFirstSection
                    , viewFirstSectionImage
                    , viewSecondSection
                    , viewSecondSectionImage
                    , viewThirdSection
                    , viewThirdSectionImage
                    , viewFourthSection
                    , viewFourthSectionImage
                    , viewFifthSection
                    , viewFifthSectionImage
                    , viewSixthSection
                    , viewSixthSectionImage
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
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__ReadingTexts)
                , class "guide-link"
                ]
                [ text "Reading Texts" ]
            ]
        , div [ class "guide-tab" ]
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
After you choose a text to read, you’ll get a brief note that orients you to the reading by giving you some context and background information. 
Click the “Start” button to begin reading. If you don’t like the text, you can use your browser’s “back” button to find a different text.
"""


viewFirstSectionImage : Html Msg
viewFirstSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/7.png"
            , alt (viewAltText "7" altTexts)
            , title (viewAltText "7" altTexts)
            ]
            []
        ]


viewSecondSection : Html Msg
viewSecondSection =
    Markdown.toHtml [] """
**2\\.**
The text may be broken in one or more sections. You can keep track of your progress at the top of your page by noting your current section and the total 
number of sections.    
"""


viewSecondSectionImage : Html Msg
viewSecondSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/8.png"
            , alt (viewAltText "8" altTexts)
            , title (viewAltText "8" altTexts)
            ]
            []
        ]


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
**3\\.**
Read the text for your current section, and try to answer the questions that follow it. There’s no penalty for selecting a wrong answer, but the app does 
keep track of the total number of questions you get right on your first attempt to answer them. So, you should try to answer the question as best you can, 
referring back to the text as much as you need to.
"""


viewThirdSectionImage : Html Msg
viewThirdSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/9.png"
            , alt (viewAltText "9" altTexts)
            , title (viewAltText "9" altTexts)
            ]
            []
        ]


viewFourthSection : Html Msg
viewFourthSection =
    Markdown.toHtml [] """
**4\\.**
As you’re reading, if you want to check on an unfamiliar word’s meaning, you can click (single tap on mobile) on any word in the text to see its dictionary 
form, grammatical information and the best English equivalent for the context. You can save any word or phrase you look up to the “My words” file.
"""


viewFourthSectionImage : Html Msg
viewFourthSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/10.png"
            , alt (viewAltText "10" altTexts)
            , title (viewAltText "10" altTexts)
            ]
            []
        ]


viewFifthSection : Html Msg
viewFifthSection =
    Markdown.toHtml [] """
**5\\.**
Be sure to read the feedback to the questions. It has been specially designed to help you learn to read more accurately. Understanding how the words fit together 
to create the meaning that they have is crucial to becoming a truly advanced reader.
"""


viewFifthSectionImage : Html Msg
viewFifthSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/11.png"
            , alt (viewAltText "11" altTexts)
            , title (viewAltText "11" altTexts)
            ]
            []
        ]


viewSixthSection : Html Msg
viewSixthSection =
    Markdown.toHtml [] """
**6\\.**
Once you’ve finished a text, you will see a summary of your reading progress. Below that, you’ll have some options: to re-read the text, find another text in 
the STAR app to read, or to follow links to outside sources related to the topic you’ve just been reading about.
"""


viewSixthSectionImage : Html Msg
viewSixthSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/12.png"
            , alt (viewAltText "12" altTexts)
            , title (viewAltText "12" altTexts)
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
