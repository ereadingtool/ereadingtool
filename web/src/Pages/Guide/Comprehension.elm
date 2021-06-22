module Pages.Guide.Comprehension exposing (..)

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
    { title = "Guide | Comprehension"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Comprehension" ]
                    , viewTabs
                    , viewFirstSection
                    , viewSecondSection
                    , viewThirdSection
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
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Strategies)
                , class "guide-link"
                ]
                [ text "Strategies" ]
            ]
        , div [ class "guide-tab" 
            , class "selected-guide-tab"
            ]
            [ a
                [ href (Route.toString Route.Guide__Comprehension)
                , class "guide-link"
                ]
                [ text "Comprehension" ]
            ]
        , div [ class "guide-tab" 
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
### Focus on Comprehension: Reading through unknown words

Even in your first language there will be texts that you can read and comprehend where you do not know every word in the text. Sometimes, 
you can figure out the meaning of the unfamiliar word from context; other times, you can look up the unfamiliar word if it seems important; 
most times, the unfamiliar word may not keep you from understanding the basic meaning of the passage.

Try these reading strategies for yourself on the text below where 30% of the words have been replaced with non-sense words.

#### Pre-reading Work:
The paragraph below starts a chapter of an English novel published in the 1860s. The title of the chapter is: A Boat on the River 

**Activity 1**. Before reading, stop and brainstorming about what might be in such a chapter. Make hypotheses. Try to visualize the possible 
scene. What does a 19th century boat on a river look like? How might people be dressed? What might be visible on the banks of the river?

**Activity 2**. After you've completed your brainstorming, go on to read the text below. You won’t know every word, but keep on reading to 
the end, and make as much sense out of the passage as you can.
"""


viewSecondSection : Html Msg
viewSecondSection =
    div [class "sample-passage"] [
        Html.em [] [ Html.text  "A Boat on the River"]
        , Html.br [] []
        , Html.br [] []
        , Html.text """
        The gapels in this boat were those of a foslaint man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, 
        nabbastly like him to be sorbicable as his fornoy. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in 
        his dispers, and his dispers loose in his waistband, kept an eager look out. He had no net, galeaft, or line, and he could not be a paplil; his boat 
        had no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a lanop of rope, and he could not be a waterman; his boat was too 
        anem and too divey to take in besder for delivery, and he could not be a river-carrier; there was no paff to what he looked for, sar he looked for 
        something, with a most nagril and searching profar. The befin, which had turned an hour before, was melucting zopt, and his eyes hasteled every little 
        furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he calbained his fornoy by 
        a calput of his head. She hasteled his face as parnly as he hasteled the river. But, in the astortant of her look there was a touch of bazad or fisd.
        """
    ]



viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
### Learning to read through unfamiliar words

How many of the comprehension questions were you able to answer correctly? Did the presence of so many unfamiliar words keep you from forming a general impression of what is going on in this passage? 

Which ones of your hypotheses about the text were accurate? Which ones did you need to abandon? Did trying to visualize what the scene might look like help you in reading the text?

How can you apply this strategy when you are reading a text in Russian?

In the next section of this strategy instruction, you will work on using context to guess the meaning of unfamiliar words.
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
