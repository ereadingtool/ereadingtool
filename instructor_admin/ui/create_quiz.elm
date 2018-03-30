import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onMouseOut, onMouseLeave)

import Array exposing (Array)

import Model exposing (Text, Question, QuestionDifficulty, Answer, textsDecoder)

import Ports exposing (selectAllInputText)


type Msg = ToggleEditableField Int | Hover Int
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String


type alias Field = {
    id : String
  , editable : Bool
  , hover : Bool }


type alias Model = {
    text : Text
  , questions : Array Question
  , fields : Array Field }

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


question_difficulties : List (String, String)
question_difficulties = [
    ("intermediate_mid", "Intermediate-Mid")
  , ("intermediate_high", "Intermediate-High")
  , ("advanced_low", "Advanced-Low")
  , ("advanced_mid", "Advanced-Mid") ]

init : (Model, Cmd Msg)
init = (Model new_text (Array.fromList [new_question]) (Array.fromList [
      {id="title", editable=False, hover=False}
    , {id="source", editable=False, hover=False}
    , {id="difficulty", editable=False, hover=False}
    , {id="body", editable=False, hover=False}
  ]), Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

generate_answers : Int -> List Answer
generate_answers n = List.map (\i -> Answer Nothing Nothing "Click to write choice " False i "")
  <| List.range 1 n

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField i -> case Array.get i model.fields of
      Just field -> case field.editable of
        True -> ({ model
                   | fields = (Array.set i { field | editable = False, hover = False } model.fields) }
              , Cmd.none)
        _ -> ({ model | fields = (Array.set i { field | editable = True } model.fields) }
              , selectAllInputText field.id)
      _ -> (model, Cmd.none)

    Hover i -> case Array.get i model.fields of
      Just field -> case field.hover of
        True -> ({ model | fields = (Array.set i { field | hover = False } model.fields  ) }
              , Cmd.none)
        _ -> ({ model | fields = (Array.set i { field | hover = True } model.fields ) }
              , Cmd.none)
      _ -> (model, Cmd.none)

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
      div [ classList [("questions", True)] ] (List.concat <| Array.toList <| Array.map view_question model.questions)
  ]

get_hover : Model -> Int -> Bool
get_hover model i = case Array.get i model.fields of
  Just field -> field.hover
  Nothing -> False

hover_attrs : Model -> Int -> List (Attribute Msg)
hover_attrs model i = [
    classList [ ("over", get_hover model i) ]
  , onMouseOver (Hover i)
  , onMouseLeave (Hover i)]

text_property_attrs : Model -> Int -> List (Attribute Msg)
text_property_attrs model i = [onClick (ToggleEditableField i)] ++ (hover_attrs model i)

view_title : Model -> Int -> Html Msg
view_title model i = Html.div (text_property_attrs model i) [
    Html.text "Title: "
  , Html.text model.text.title
  ]

edit_title : Model -> Int -> Html Msg
edit_title model i = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.title
      , attribute "id" "title"
      , onInput UpdateTitle
      , onBlur (ToggleEditableField i) ] [ ]

view_source : Model -> Int -> Html Msg
view_source model i = Html.div (text_property_attrs model i) [
     Html.text "Source: "
   , Html.text model.text.source
  ]

edit_source : Model -> Int -> Html Msg
edit_source model i = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.source
      , attribute "id" "source"
      , onInput UpdateSource
      , onBlur (ToggleEditableField i) ] [ ]

view_difficulty : Model -> Int -> Html Msg
view_difficulty model i = Html.div (text_property_attrs model i) [
      Html.text "Difficulty:"
    , Html.select [
        onInput UpdateDifficulty ] [
      Html.optgroup [attribute "value" model.text.difficulty]
        (List.map (\(k,v) -> Html.option [] [Html.text v]) <| question_difficulties)
    ]
  ]

edit_difficulty : Model -> Int -> Html Msg
edit_difficulty model i = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.difficulty
      , attribute "id" "difficulty"
      , onInput UpdateDifficulty
      , onBlur (ToggleEditableField i) ] [ ]


view_body : Model -> Int -> Html Msg
view_body model i = Html.div (text_property_attrs model i) [
    Html.text "Text: "
  , Html.text model.text.body ]

edit_body : Model -> Int -> Html Msg
edit_body model i = Html.textarea [
        onInput UpdateBody
      , attribute "id" "body"
      , onBlur (ToggleEditableField i) ] [ Html.text model.text.body ]

view_editable_field : Model -> Int -> (Model -> Int -> Html Msg) -> (Model -> Int -> Html Msg) -> Html Msg
view_editable_field model i view edit = case Array.get i model.fields of
   Just field -> case field.editable of
     True -> (edit model i)
     _ -> (view model i)
   _ -> (view model i)

view_create_text : Model -> Html Msg
view_create_text model = div [ classList [("text_properties", True)] ] [
      div [ classList [("text_property_items", True)] ] [
          view_editable_field model 0 view_title edit_title
        , view_editable_field model 1 view_source edit_source
        , view_editable_field model 2 view_difficulty view_difficulty
      ]
      , div [ classList [("body",True)] ]  [ view_editable_field model 3 view_body edit_body ]
  ]

view : Model -> Html Msg
view model = div [] [
      (view_header model)
    , (view_preview model)
    , (view_create_text model)
    , (view_questions model)
  ]
