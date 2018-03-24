import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http exposing (..)

import Model exposing (Text, Texts, Model, textsDecoder)
import Config exposing (..)

-- UPDATE
type Msg = Update (Result Http.Error (List Text))

type alias Filter = List String

init : (Model, Cmd Msg)
init = (Model  [], updateTexts [])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


updateTexts : Filter -> Cmd Msg
updateTexts filter = let request = Http.get text_api_endpoint textsDecoder in
  Http.send Update request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update (Ok texts) ->
      (Model texts, Cmd.none)
    -- handle user-friendly msgs
    Update (Err _) ->
      (model, Cmd.none)


main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_header : Model -> Html Msg
view_header model =
    div [ classList [("header", True)] ] [
        text "E-Reader"
      , div [ classList [("menu", True)] ] [
          span [ classList [("menu_item", True)] ] [
            text ""
          ]
        ]
    ]

view_preview : Model -> Html Msg
view_preview model =
    div [ classList [("preview", True)] ] [
        text ""
      , div [ classList [("preview_menu", True)] ] [
          span [ classList [("menu_item", True)] ] [
              Html.button [] [ Html.text "Preview" ]
            , Html.input [attribute "placeholder" "Search texts.."] []
          ]
        ]
    ]


view_filter : Model -> Html Msg
view_filter model = div [classList [("filter_items", True)] ] [
     div [classList [("filter", True)] ] [
         Html.input [attribute "placeholder" "Search texts.."] []
       , Html.button [] [Html.text "Create Text"]
     ]
 ]

view_choices : Model -> Int -> List (Html Msg)
view_choices model places =
     List.map (\i ->
       div [ classList [("answer_item", True)] ] [
            Html.input [attribute "type" "radio"] []
         ,  Html.text <| "Click to write Choice " ++ (toString i)
       ]
     ) <| List.range 1 places

view_create_question : Model -> List (Html Msg)
view_create_question model = [
      div [] [Html.input [attribute "type" "checkbox"] []]
   ,  div [classList [("question_item", True)] ] [ Html.text "Click to write the question text" ]
 ] ++ (view_choices model 4)

view_create_questions : Model -> Html Msg
view_create_questions model = div [ classList [("question_section", True)] ] [
      div [ classList [("questions", True)] ] (view_create_question model)
  ]


view_create_title : Model -> Html Msg
view_create_title model = div [ classList [("create_text", True)] ] [
      div [ classList [("create_title", True)] ] [ Html.text "title" ]
  ]

view_footer : Model -> Html Msg
view_footer model = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text <| "Showing " ++ toString (List.length model.texts) ++ " entries"
    ]
 ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
      (view_header model)
    , (view_preview model)
    , (view_create_title model)
    , (view_create_questions model)
  ]
