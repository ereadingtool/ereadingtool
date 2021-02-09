module Pages.Top exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Html exposing (..)
import Html.Attributes exposing (class, href, id)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)


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
    { title = "Steps To Advanced Reading"
    , body =
        [ div [ id "home-wrapper" ]
            [ viewHeroSection
            , viewDescriptionSection
            , viewFeaturesSection
            ]
        ]
    }


viewHeroSection : Html Msg
viewHeroSection =
    div [ class "hero" ]
        []


viewDescriptionSection : Html Msg
viewDescriptionSection =
    div [ class "description" ]
        [ h2 [ class "description-heading" ] [ text "Welcome to STAR" ]
        , p [ class "description-text" ]
            [ text
                """
               Steps to Advanced Reading is a free mobile-friendly web application that 
               helps students learning to read authentic non-fiction texts 
               in Russian. Texts range from short announcements to longer 
               news items and cover topics like news, biography, economics, 
               history, international relations, culture, society and sports.
               """
            ]
        ]


viewFeaturesSection : Html Msg
viewFeaturesSection =
    div [ class "features" ]
        [ div [ class "features-text" ]
            [ text "The STAR site"
            , ul []
                [ li []
                    [ text "Lets you read in short 5-10 minute sessions" ]
                , li []
                    [ text "Uses a question and answer approach to check your understanding" ]
                , li []
                    [ text "Provides easy-access vocabulary help so you can keep on reading" ]
                , li []
                    [ text "Helps you track your progress" ]
                ]
            , div
                []
                [ a [ href (Route.toString Route.Guide__GettingStarted) ] [ text "Learn more" ]
                , text " or "
                , a [ href (Route.toString Route.Signup__Student) ] [ text "Sign up now" ]
                ]
            ]
        ]
