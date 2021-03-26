module Pages.Guide.ReadingTexts exposing (Model, Msg, Params, page)

import Html exposing (..)
import Html.Attributes exposing (class, href, id, src)
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
                    , viewFirstImage
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
                [ text "Page 2" ]
            ]
        , div [ class "guide-tab" ]
            [ a
                [ href (Route.toString Route.Guide__Page3)
                , class "guide-link"
                ]
                [ text "Page 3" ]
            ]
        ]


viewFirstSection : Html Msg
viewFirstSection =
    Markdown.toHtml [] """

## First Section

Many things were said here.

"""


viewFirstImage : Html Msg
viewFirstImage =
    div [] [ img [ src "/public/img/tutorial/14-right.jpg" ] [] ]
