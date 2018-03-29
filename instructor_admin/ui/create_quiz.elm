import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onMouseOut, onMouseLeave)

import Dict

import Model exposing (Text, Question, Answer, textsDecoder)

import Ports exposing (selectAllInputText)


type Msg = ToggleEditableField String | Hover String
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String


type alias Field = {
    editable : Bool
  , hover : Bool}


type alias Model = { text : Text, editable_fields: (Dict.Dict String Field), questions: List Question }

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


new_question : Question
new_question = {
    id = Nothing
  , text_id = Nothing
  , created_dt = Nothing
  , modified_dt = Nothing
  , body = "Click to write the question text."
  , order = 1
  , answers = (generate_answers 4)
  , question_type = "main_idea"}


init : (Model, Cmd Msg)
init = (Model new_text (Dict.fromList [
      ("title", Field False False)
    , ("source", Field False False)
    , ("difficulty", Field False False)
    , ("body", Field False False)
  ]) [new_question], Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

generate_answers : Int -> List Answer
generate_answers n = List.map (\i -> Answer Nothing Nothing "Click to write choice " False i "")
  <| List.range 1 n

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField field ->
      ({ model | editable_fields = Dict.update field
        (\v -> case v of
          Just field -> case field.editable of
            True -> Just { field | editable = False, hover = False }
            _ -> Just { field | editable = True, hover = True }
          _ -> v) model.editable_fields }, selectAllInputText field)

    Hover field ->
      ({ model | editable_fields = Dict.update field
        (\v -> case v of
          Just field -> case field.hover of
            True -> Just { field | hover = False }
            _ -> Just { field | hover = True }
          _ -> v) model.editable_fields }, selectAllInputText field)

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

view_answer : Question -> Answer -> Html Msg
view_answer question answer =
   div [ classList [("answer_item", True)] ] [
        Html.input [
            attribute "type" "radio"
          , attribute "name" (String.join "_" ["question", (toString question.order), "answer"])
        ] []
     ,  Html.text <| "Click to write Choice " ++ (toString answer.order)
   ]

view_question : Question -> List (Html Msg)
view_question question = [
      div [] [Html.input [attribute "type" "checkbox"] []]
   ,  div [classList [("question_item", True)] ] [ Html.text question.body ]
 ] ++ (List.map (view_answer question) question.answers)

view_questions : Model -> Html Msg
view_questions model = div [ classList [("question_section", True)] ] [
      div [ classList [("questions", True)] ] (List.concat <| List.map view_question model.questions)
  ]

get_hover : Model -> String -> Bool
get_hover model field = case Dict.get field model.editable_fields of
  Just field -> field.hover
  Nothing -> False

hover_attrs : Model -> String -> List (Attribute Msg)
hover_attrs model field = [
    classList [ ("over", get_hover model field) ]
  , onMouseOver (Hover field)
  , onMouseLeave (Hover field)]

text_property_attrs : Model -> String -> List (Attribute Msg)
text_property_attrs model field = [onClick (ToggleEditableField field)] ++ (hover_attrs model field)

view_title : Model -> Html Msg
view_title model = Html.div (text_property_attrs model "title") [ Html.text model.text.title ]

edit_title :Model -> Html Msg
edit_title model = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.title
      , attribute "id" "title"
      , onInput UpdateTitle
      , onBlur (ToggleEditableField "title") ] [ ]

view_source : Model -> Html Msg
view_source model = Html.div (text_property_attrs model "source") [ Html.text model.text.source ]

edit_source : Model -> Html Msg
edit_source model = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.source
      , attribute "id" "source"
      , onInput UpdateSource
      , onBlur (ToggleEditableField "source") ] [ ]

view_difficulty : Model -> Html Msg
view_difficulty model = Html.div (text_property_attrs model "difficulty") [ Html.text model.text.difficulty ]

edit_difficulty : Model -> Html Msg
edit_difficulty model = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.difficulty
      , attribute "id" "difficulty"
      , onInput UpdateDifficulty
      , onBlur (ToggleEditableField "difficulty") ] [ ]


view_body : Model -> Html Msg
view_body model = Html.div (text_property_attrs model "body") [ Html.text model.text.body ]

edit_body : Model -> Html Msg
edit_body model = Html.textarea [
        onInput UpdateBody
      , attribute "id" "body"
      , onBlur (ToggleEditableField "body") ] [ Html.text model.text.body ]

view_editable_field : String -> Model -> (Model -> Html Msg) -> (Model -> Html Msg) -> Html Msg
view_editable_field field model view edit = case Dict.get field model.editable_fields of
   Just field -> case field.editable of
     True -> edit model
     _ -> view model
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
    , (view_questions model)
  ]
