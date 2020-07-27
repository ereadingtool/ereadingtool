module Pages.About exposing (Model, Msg, Params, page)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (alt, class, id, src, title)
import Spa.Document exposing (Document)
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
    { title = "About"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "title" ] [ text "About this website" ]
                , p []
                    [ text
                        """
                        This page will give you an overview of the STAR (Steps to Advanced Reading) website’s functionality without
                        requiring you to create an account. The main function of the website is to allow students to read texts at
                        and above their proficiency level in Russian and answer comprehension questions on them. The secondary
                        function of the site allows students to save words encountered in texts to flashcards and to review and
                        build their vocabulary. The texts and comprehension questions included in the site have been leveled
                        according the to ACTFL Proficiency Guidelines, and cover the proficiency ranges Intermediate-Mid through
                        Advanced-Mid.       
                        """
                    ]
                , p []
                    [ text
                        """
                        The goal of the website is to prepare students to read better in order to reach the ILR-2 level in Reading
                        and qualify for the Overseas Flagship program.
                        """
                    ]
                , p []
                    [ text
                        """
                        The pedagogical model is one of microlearning, where students who engage in regular curated reading and
                        vocabulary learning should become more proficient readers. The website has been designed to be
                        mobile-friendly. The screenshots show how the website looks on a Samsung Galaxy J7 Prime phone using
                        the Android operating system.
                        """
                    ]
                , ol []
                    [ li []
                        [ p []
                            [ text
                                """
                                The starting place for users is the login page for the STAR website.
                                On this page students can create an account, or log in if they already have established an account.
                                Instructors who want to add or edit texts on this site can access the instructor log in from this page.
                                """
                            ]
                        , div [ class "screenshot" ]
                            [ img
                                [ src "public/img/tutorial/1.jpg"
                                , alt (viewAltText "1" altTexts)
                                , title (viewAltText "1" altTexts)
                                ]
                                []
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                When students log into the STAR website, they immediately see their Profile page.
                                The profile page contains information related to the user and links to the site’s two main functions:
                                reading texts and reviewing flashcards.  On the Profile page, students can read through the
                                descriptions of the various proficiency levels and choose the one that they feel fits their current
                                level and create their own username (which is shown at the top right corner of the page).
                                """
                            ]
                        , div [ class "screenshot" ]
                            [ img
                                [ src "public/img/tutorial/2.jpg"
                                , alt (viewAltText "2" altTexts)
                                , title (viewAltText "2" altTexts)
                                ]
                                []
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                The Student Profile page also presents statistics about the students’ use of the site and reading
                                performance. For each proficiency level and cumulatively, they can see how many texts they read and
                                what percentage of questions they answered correctly in different time frames. They can download this
                                information as a PDF which they can choose to share with an advisor.
                                """
                            ]
                        , div [ class "screenshot" ]
                            [ img
                                [ src "public/img/tutorial/3.jpg"
                                , alt (viewAltText "3" altTexts)
                                , title (viewAltText "3" altTexts)
                                ]
                                []
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                When students follow the “Find a text to read” link, they land on the Text Search page, where
                                students can use three different filters to find texts to read. The first filter is for the text and
                                question difficulty. If the student has set a difficulty level on their Profile page, then that level
                                will be pre-selected in this filter. Students can easily select and deselect levels.
                                """
                            ]
                        , div [ class "screenshot" ]
                            [ img
                                [ src "public/img/tutorial/4.jpg"
                                , alt (viewAltText "4" altTexts)
                                , title (viewAltText "4" altTexts)
                                ]
                                []
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                The second filter sorts texts by topic. Each text is tagged by which topics they address, and students
                                can select what sounds interesting to them. There are 19 subject area tags.
                                """
                            ]
                        , div [ class "screenshot" ]
                            [ img
                                [ src "public/img/tutorial/5.jpg"
                                , alt (viewAltText "5" altTexts)
                                , title (viewAltText "5" altTexts)
                                ]
                                []
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                The final filter helps students find texts they’ve previously completed reading, texts that they
                                haven’t finished reading, and texts they have not started. Once students have selected their desired
                                filters, they can see a list of texts fitting those criteria. Each entry in the list includes the
                                reading’s title, difficulty level, author, number of text sections, topics, and if applicable, the
                                last time the text was read and the number of questions answered correctly.
                                """
                            ]
                        , div [ class "screenshot" ]
                            [ img
                                [ src "public/img/tutorial/6.jpg"
                                , alt (viewAltText "6" altTexts)
                                , title (viewAltText "6" altTexts)
                                ]
                                []
                            ]
                        , p []
                            [ text
                                """
                                If students do not use any of the filters (i.e., difficulty, topic tags, and read status),
                                they will find a full list of texts included in the site.
                                """
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                Once a student has found a text to read, they click on the title and come to a brief pre-reading screen
                                that orients them to the genre and type of text.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/7.jpg"
                                    , alt (viewAltText "7" altTexts)
                                    , title (viewAltText "7" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                After clicking “start,” students begin to read the text. While short texts may only have one section,
                                longer texts will be broken up into multiple sections.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/8.jpg"
                                    , alt (viewAltText "8" altTexts)
                                    , title (viewAltText "8" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                At the the end of each text section, there are comprehension questions with three or four possible
                                answers. To ensure that students are understanding what they have just read, they must answer the
                                questions before proceeding to the next section of the text.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/9.jpg"
                                    , alt (viewAltText "9" altTexts)
                                    , title (viewAltText "9" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                At the the end of each text section, there are comprehension questions with three or four possible
                                answers. To ensure that students are understanding what they have just read, they must answer the
                                questions before proceeding to the next section of the text.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/10.jpg"
                                    , alt (viewAltText "10" altTexts)
                                    , title (viewAltText "10" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                When student answers an answer correctly, the answer box is bordered in green. When they answer a
                                question incorrectly, it is bordered in red. Additionally, the student receives feedback explaining
                                why their selected answer was correct or incorrect, and if the student answered incorrectly, the
                                feedback also tells which answer was correct and why. The feedback boxes provide a parsed bilingual
                                guide to the part of the text related to the question.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/11-left.jpg"
                                    , alt (viewAltText "11-left" altTexts)
                                    , title (viewAltText "11-left" altTexts)
                                    ]
                                    []
                                ]
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/11-right.jpg"
                                    , alt (viewAltText "11-right" altTexts)
                                    , title (viewAltText "11-right" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                At the end of a text, the student will see a post-reading page, which tells them how many comprehension
                                questions they answered correctly for that text, links to related readings outside of the website, and
                                a message directing them back to the Search Texts page.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/12.jpg"
                                    , alt (viewAltText "12" altTexts)
                                    , title (viewAltText "12" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                Once a student has added words to their flashcard deck, they can review those words. Students can work
                                with flashcards in two modes “Review Only” and “Review and Answer”.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/13.jpg"
                                    , alt (viewAltText "13" altTexts)
                                    , title (viewAltText "13" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                When students are reviewing a flashcard in “Review Only” mode, they will initially see the Russian word
                                and the context that they encountered the word in. They can guess the word, and then double-click the
                                flashcard to flip it over and see if their guess was correct.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/14-left.jpg"
                                    , alt (viewAltText "14-left" altTexts)
                                    , title (viewAltText "14-left" altTexts)
                                    ]
                                    []
                                ]
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/14-right.jpg"
                                    , alt (viewAltText "14-right" altTexts)
                                    , title (viewAltText "14-right" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , li []
                        [ p []
                            [ text
                                """
                                When students are reviewing a flashcard in “Review and Answer” mode, they must type a translation for
                                the word on the flashcard. Once they have answered correctly, they will be asked to judge how difficult
                                it was for them to answer the card. This mode uses spaced repetition, so their self-assessment will
                                determine when they will next encounter the card.
                                """
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/15-left.jpg"
                                    , alt (viewAltText "15-left" altTexts)
                                    , title (viewAltText "15-left" altTexts)
                                    ]
                                    []
                                ]
                            , div [ class "screenshot" ]
                                [ img
                                    [ src "public/img/tutorial/15-right.jpg"
                                    , alt (viewAltText "15-right" altTexts)
                                    , title (viewAltText "15-right" altTexts)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    }



-- ALT TEXTS


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
