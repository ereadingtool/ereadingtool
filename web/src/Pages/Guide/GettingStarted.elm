module Pages.Guide.GettingStarted exposing (Model, Msg, Params, page)

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
    { title = "Guide | Getting Started"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "guide-title" ] [ text "Getting Started" ]
                    , viewTabs
                    , viewFirstSection
                    , viewFirstSectionImage
                    , viewSecondSection
                    , viewSecondSectionImage
                    , viewThirdSection
                    , viewThirdSectionImage
                    , viewFourthSection
                    , viewFifthSection
                    , viewFifthSectionImage
                    , viewSixthSection
                    , viewSixthSectionImage
                    , viewSeventhSection
                    , viewSeventhImage
                    ]
                ]
            ]
        ]
    }


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [] """
This page will give you an overview of the STAR (Steps to Advanced Reading) website’s functionality without
requiring you to create an account. The main function of the website is to allow students to read texts at
and above their proficiency level in Russian and answer comprehension questions on them. The secondary
function of the site allows students to save words encountered in texts to flashcards and to review and
build their vocabulary. The texts and comprehension questions included in the site have been leveled
according the to ACTFL Proficiency Guidelines, and cover the proficiency ranges Intermediate-Mid through
Advanced-Mid.

The goal of the website is to prepare students to read better in order to reach the ILR-2 level in Reading
and qualify for the Overseas Flagship program.

The pedagogical model is one of microlearning, where students who engage in regular curated reading and
vocabulary learning should become more proficient readers. The website has been designed to be
mobile-friendly. The screenshots show how the website looks on a Samsung Galaxy J7 Prime phone using
the Android operating system.

**1\\.** 
The STAR website is not connected to any university’s user account, so if you are using the site 
for the first time, you will need to create a new account. The program is free, and to sign up 
you only need to give a functioning email address and create a password, and choose a reading 
difficulty level. If you already have an account, you can log in.
"""


viewFirstSectionImage : Html Msg
viewFirstSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/1.png"
            , alt (viewAltText "1" altTexts)
            , title (viewAltText "1" altTexts)
            ]
            []
        ]


viewSecondSection : Html Msg
viewSecondSection =
    -- Since Markdown doesn't let you continue a numbered list, we must escape and use plaintext numbering
    Markdown.toHtml [] """
**2\\.** 
If you’ve already created an account, then you can just log in to the app.
"""


viewSecondSectionImage : Html Msg
viewSecondSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/2.png"
            , alt (viewAltText "2" altTexts)
            , title (viewAltText "2" altTexts)
            ]
            []
        ]


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
**3\\.** 
Once you’re logged in, you will land on your “Profile” page, where you will 
find information about your progress and website settings.
"""


viewThirdSectionImage : Html Msg
viewThirdSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/3.png"
            , alt (viewAltText "3" altTexts)
            , title (viewAltText "3" altTexts)
            ]
            []
        ]


viewFourthSection : Html Msg
viewFourthSection =
    Markdown.toHtml [] """
**4\\.** Select “Texts” from the blue banner (or the hamburger menu on mobile) at the top of your screen to 
find a text to read.
"""


viewFifthSection : Html Msg
viewFifthSection =
    Markdown.toHtml [] """
**5\\.** You can browse through all the texts available for your reading proficiency level, or you can 
narrow the range with topic tags or with reading status.

**Tags**
By selecting tags for topics that are of interest to you, you can narrow the range of available 
texts. When you select multiple tags, you will get a list of the texts that have either tag. 
Selecting some combinations of topic tags and proficiency levels will result in no texts being 
found; adjust tags or your proficiency level.
"""


viewFifthSectionImage : Html Msg
viewFifthSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/4.png"
            , alt (viewAltText "4" altTexts)
            , title (viewAltText "4" altTexts)
            ]
            []
        ]


viewSixthSection : Html Msg
viewSixthSection =
    Markdown.toHtml [] """
**Read Status**
“Unread” returns a list of texts that you’ve not read yet; “In Progress” will let you find texts 
you’ve started reading, but haven’t finished; “Read” allows you to go back to texts that you have
previously completed.
"""


viewSixthSectionImage : Html Msg
viewSixthSectionImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/5.png"
            , alt (viewAltText "5" altTexts)
            , title (viewAltText "5" altTexts)
            ]
            []
        ]


viewSeventhSection : Html Msg
viewSeventhSection =
    Markdown.toHtml [] """
**6\\.** In the list of texts for your filters, for each entry you will see the title of the text, difficulty 
level, author, number of sections, tags, and your status with the text.
"""


viewSeventhImage : Html Msg
viewSeventhImage =
    div [ class "guide-image-container" ]
        [ img
            [ class "guide-image"
            , src "/public/img/tutorial/student/6.png"
            , alt (viewAltText "6" altTexts)
            , title (viewAltText "6" altTexts)
            ]
            []
        ]


viewTabs : Html Msg
viewTabs =
    div [ class "guide-tabs" ]
        [ div
            [ class "guide-tab"
            , class "leftmost-guide-tab"
            , class "selected-guide-tab"
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
        , div [ class "guide-tab" ]
            [ a
                [ href (Route.toString Route.Guide__Strategies)
                , class "guide-link"
                ]
                [ text "Strategies" ]
            ]
        ]



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
        [ ( "1", "Screenshot of signup page" )
        , ( "2", "Screenshot of login page" )
        , ( "3", "Screenshot of profile page with hints active" )
        , ( "4", "Screenshot of text search filter Advanced Mid difficulty level" )
        , ( "5", "Screenshot of text search filter for unread text" )
        , ( "6", "Screenshot of text search results" )
        ]
