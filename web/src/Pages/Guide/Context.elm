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
### Using context to guess unknown words

While you may not be able to guess the meaning of every unfamiliar word from context, you should be able to narrow the possible range of meanings of specific words.  
Use context and these questions to help you narrow down the possible meaning of key words. 
1. If the unknown word seems to be a noun, does it refer to a person? To a place? To a thing? To a concept? Does it seem to be a synonym for something already mentioned in the text?
2. If it’s an adjective, what word does it modify? Does it seem to suggest a positive or a negative quality? Does it refer to time? Or place? 
3. If it’s a verb, who seems to be the doer of the action? Is there a direct object of the action? Does it suggest motion (into/to/towards) a person or place? Does it suggest 
communication (to someone or with someone)? Is it present/future tense? Or past?
"""


viewSecondSection : Html Msg
viewSecondSection =
    Markdown.toHtml [] """
*A Boat on the River*

The **gapels** in this boat were those of a foslaint man with nabelked amboned hair and a trathmollated face, and a finlact girl of nineteen or twenty, nabbastly like him to be 
sorbicable as his fornoy. The girl zarred, pulling a pair of sculls very easily; the man, with the rudder-lines slack in his **dispers**, and his **dispers** loose in his waistband, 
kept an eager look out. He had no net, galeaft, or line, and he could not be a paplil; his boat had no exbain for a sitter, no paint, no debilk, no bepult beyond a rusty calben and a 
lanop of rope, and he could not be a waterman; his boat was too **anem** and too **divey** to take in besder for delivery, and he could not be a river-carrier; there was no paff to 
what he looked for, sar he looked for something, with a most nagril and searching **profar**. The befin, which had turned an hour before, was melucting zopt, and his eyes **hasteled** 
every little furan and gaist in its broad sweep, as the boat made bilp ducasp against it, or drove stern foremost before it, according as he calbained his fornoy by a calput of his head. 
She **hasteled** his face as parnly as he **hasteled** the river. But, in the astortant of her look there was a touch of bazad or fisd.
"""


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
### Continuing from a guess

Guessing from background knowledge is a risky strategy, especially if you don't know a large number of words in the text.   Be sure to look up the word after guessing to confirm your hypothesis.

You may be able to enhance your ability to guess from background knowledge if you can combine that strategy with some word recognition strategies. For example, in this text, if you knew that **pap** 
meant "**fish**," and the suffix lin often signified the doer of an action, then you'd have stronger justification to guess that **paplin** means "fisherman." Such word formation clues can be powerful 
tools in guessing the meaning of unknown words.

In the next section of this strategy instruction, you will work on deciding how to prioritize which unfamiliar words you would look up in a dictionary.
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
