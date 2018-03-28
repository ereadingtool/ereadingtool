import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput)

import Dict

import Model exposing (Text, Question, textsDecoder)

import Ports exposing (selectAllInputText)


type Msg = ToggleEditableField String
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String


type alias Model = { text : Text, questions: List Question, editable_fields: (Dict.Dict String Bool) }

type alias Filter = List String

new_text : Text
new_text = {
    id = Nothing
  , title = "title"
  , created_dt = Nothing
  , modified_dt = Nothing
  , source = "source"
  , difficulty = "difficulty"
  , question_count = 0
  , body = "text" }


--new_question : Question
--new_question = {}

init : (Model, Cmd Msg)
init = (Model new_text [] (Dict.fromList [
      ("title", False)
    , ("source", False)
    , ("difficulty", False)
    , ("body", False)
  ]) , Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField field ->
      ({ model | editable_fields = Dict.update field
        (\v -> case v of
          Just True -> Just False
          _ -> Just True) model.editable_fields }, selectAllInputText field)


    UpdateTitle title -> ({ model | text = { text | title = title }}, Cmd.none)
    UpdateSource source ->  ({ model | text = { text | source = source }}, Cmd.none)
    UpdateDifficulty difficulty -> ({ model | text = { text | difficulty = difficulty }}, Cmd.none)
    UpdateBody body -> ({ model | text = { text | body = body }}, Cmd.none)


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

view_title : Model -> Html Msg
view_title model = Html.div [onClick (ToggleEditableField "title")] [
  Html.text model.text.title ]

edit_title :Model -> Html Msg
edit_title model = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.title
      , attribute "id" "title"
      , onInput UpdateTitle
      , onBlur (ToggleEditableField "title") ] [ ]

view_source : Model -> Html Msg
view_source model = Html.div [onClick (ToggleEditableField "source")] [ Html.text model.text.source ]

edit_source : Model -> Html Msg
edit_source model = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.source
      , attribute "id" "source"
      , onInput UpdateTitle
      , onBlur (ToggleEditableField "source") ] [ ]

edit_difficulty : Model -> Html Msg
edit_difficulty model = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.difficulty
      , attribute "id" "difficulty"
      , onInput UpdateDifficulty
      , onBlur (ToggleEditableField "difficulty") ] [ ]

view_difficulty : Model -> Html Msg
view_difficulty model = Html.div [onClick (ToggleEditableField "difficulty")] [ Html.text model.text.difficulty ]

edit_body : Model -> Html Msg
edit_body model = Html.textarea [
        onInput UpdateBody
      , attribute "id" "body"
      , onBlur (ToggleEditableField "body") ] [ Html.text model.text.body ]

view_body : Model -> Html Msg
view_body model = Html.div [onClick (ToggleEditableField "body")] [ Html.text model.text.body ]

view_editable_field : String -> Model -> (Model -> Html Msg) -> (Model -> Html Msg) -> Html Msg
view_editable_field field model view edit = case Dict.get field model.editable_fields of
   Just True -> edit model
   _ -> view model

view_create_text : Model -> Html Msg
view_create_text model = div [ classList [("text_properties", True)] ] [
      div [ classList [("text_property_items", True)] ] [
          view_editable_field "title" model view_title edit_title
        , view_editable_field "source" model view_source edit_source
        , view_editable_field "difficulty" model view_difficulty edit_difficulty
      ]
      , div [ classList [("body",True)] ]  [ view_editable_field "body" model view_body edit_body ]
  ]

view : Model -> Html Msg
view model = div [] [
      (view_header model)
    , (view_preview model)
    , (view_create_text model)
    , (view_create_questions model)
  ]
