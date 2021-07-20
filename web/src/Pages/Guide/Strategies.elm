module Pages.Guide.Strategies exposing (..)

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
    { title = "Guide | Strategies"
    , body =
        [ div [ id "body" ]
            [ div [ id "about" ]
                [ div [ id "about-box" ]
                    [ div [ id "title" ] [ text "Strategies" ]
                    , viewTabs
                    , viewFirstSection
                    , viewSecondSection
                    , viewThirdSection
                    , viewFourthSection
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
### How to approach a text

#### Preview and get ready to read.
If you know the general topic of the text (from the teacher, or the title, or an illustration), take a minute to formulate some ideas that you think are likely to be referenced in a text on that topic.

Then approach the text to see if any of your initial assumptions are referenced in it. It’s also useful when you realize that your initial assumptions are NOT mentioned in the text. Keep an open mind 
as you read the text for the first time.

Take stock of your first reading and how it lined up with your assumptions. 
"""


viewSecondSection : Html Msg
viewSecondSection =
    Markdown.toHtml [] """
#### Reading for deeper comprehension.

Now read the text (sentence, paragraph) again. This time around, try to get as much as possible out of the text without drawing on your assumptions.

When you’ve gotten to the end of this reading, try to summarize for yourself the main points by seeing how many questions like these you can answer: What happened? Who did it? When? Where? Why? How?

Don’t worry if you can’t answer all those questions on the first deep reading. Go back and read again. Confirm your answers to the main points that you did get. Add details to those points or find the connections between them.
If you’ve been having trouble reading to the end of the text (or paragraph or sentence), keep on reading even if you may lose the thread of what’s happening for a while.

Now summarize the fuller picture you’ve gotten of the text (or sentence or paragraph).
"""


viewThirdSection : Html Msg
viewThirdSection =
    Markdown.toHtml [] """
#### Confirming details and prioritizing words to look up.


After reading through a text twice or three times, you probably have a good idea of what words you need to check to make sure your hypotheses about the text are correct.

Prioritize the words that you look up by picking key nouns or verbs first. They will give you more of the bones or the skeleton of the sentence. If you’ve got a good idea about all the “bones” or specific 
facts, then you might check whether you really understand the relationship between the facts by looking up the connectors that hold them together. If you’re sure of the facts, but you can’t make out the 
writer's attitude to the facts, look up some of the adjectives and adverbs since they will often reveal the author’s evaluation of the facts.

Before you click to see a translation, take a guess about what the word means.Once you’ve looked up a word, fit the word into the whole sentence where it appears. Does confirming that word help you figure 
out the rest of the sentence? If so, move on to the next sentence, and see if you can go further.
"""


viewFourthSection : Html Msg
viewFourthSection =
    Markdown.toHtml [] """
#### Read and re-read. 

As you get more words, re-read the passage and develop a firmer understanding of each sentence and how they add meaning to the whole paragraph. 
Re-reading parts of the text that you've already figured out will help you learn the vocabulary in the text, and will help you begin to see patterns about which words often are used together 
(i.e.,  школьные учебники =school textbooks, иметь право = to have the right to) and how words fit together (i.e., that verb takes an object in the dative case, that preposition goes with the genitive case). 
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
