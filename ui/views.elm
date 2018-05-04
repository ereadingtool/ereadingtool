module Views exposing (view_filter, view_header, view_footer)

import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Flags exposing (CSRFToken)


view_header : Html msg
view_header =
    div [ classList [("header", True)] ] [
        text "E-Reader"
      , div [ classList [("menu", True)] ] [
          span [ classList [("menu_item", True)] ] [ Html.a [attribute "href" "/admin"] [ Html.text "Quizzes" ] ]
        , span [ classList [("menu_item", True)] ] [ Html.a [attribute "href" "/login/student/"] [ Html.text "Student Login" ] ]
        , span [ classList [("menu_item", True)] ] [ Html.a [attribute "href" "/login/instructor/"] [ Html.text "Instructor Login" ] ]
        , span [ classList [("menu_item", True)] ] [ Html.text "User Profile" ]
        ]
    ]

view_filter : Html msg
view_filter = div [classList [("filter_items", True)] ] [
     div [classList [("filter", True)] ] [
         Html.input [attribute "placeholder" "Search texts.."] []
       , Html.a [attribute "href" "/admin/create-quiz"] [Html.text "Create Text"]
     ]
 ]

view_footer : Html msg
view_footer = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text ""
    ]
 ]
