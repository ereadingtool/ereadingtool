import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput)

import Http exposing (..)

import Model exposing (Text, Texts, textsDecoder)
import Config exposing (..)

type Msg = Update (Result Http.Error (List Text)) | EditTitle | UpdateTitle String

type alias Model = { texts : List Text, editTitle : Bool, title: String }

type alias Filter = List String

init : (Model, Cmd Msg)
init = (Model  [] False "title", updateTexts [])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


updateTexts : Filter -> Cmd Msg
updateTexts filter = let request = Http.get text_api_endpoint textsDecoder in
  Http.send Update request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    EditTitle ->
      ({ model | editTitle = if model.editTitle then False else True }, Cmd.none)
    UpdateTitle title ->
      ({ model | title = title }, Cmd.none)
    Update (Ok texts) ->
      ({ model | texts = texts}, Cmd.none)
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
            Html.input [attribute "type" "radio", attribute "name" "question_1_answers"] []
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


view_edit_title : Model -> Html Msg
view_edit_title model = if model.editTitle then
    Html.input [attribute "type" "textbox", attribute "value" model.title, onInput UpdateTitle, onBlur EditTitle] [ ]
  else
    Html.span [onClick EditTitle] [ Html.text model.title ]


view_create_title : Model -> Html Msg
view_create_title model = div [ classList [("create_text", True)] ] [
      div [ classList [("create_title", True)] ] [
        view_edit_title model
      ]
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
