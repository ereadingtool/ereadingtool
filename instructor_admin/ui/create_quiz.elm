import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onMouseOut, onMouseLeave)

import Array exposing (Array)

import Model exposing (Text, Question, Answer, textsDecoder)

import Ports exposing (selectAllInputText)


type FieldType = TextField | QuestionField

type Msg = ToggleEditableField FieldType Int | Hover FieldType Int
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String
  | UpdateQuestionBody Int Question String


type alias Field = {
    id : String
  , editable : Bool
  , hover : Bool
  , field_type : FieldType }


type alias Model = {
    text : Text
  , questions : Array Question
  , text_fields : Array Field
  , question_fields : Array Field }

type alias Filter = List String

new_text : Text
new_text = {
    id = Nothing
  , title = "title"
  , created_dt = Nothing
  , modified_dt = Nothing
  , source = "source"
  , difficulty = ""
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


initial_questions : Array Question
initial_questions = (Array.fromList [new_question])

init : (Model, Cmd Msg)
init = (Model new_text initial_questions (Array.fromList [
      {id="title", field_type=TextField, editable=False, hover=False}
    , {id="source", field_type=TextField, editable=False, hover=False}
    , {id="difficulty", field_type=TextField, editable=False, hover=False}
    , {id="body", field_type=TextField, editable=False, hover=False}
  ]) (Array.map generate_question_field initial_questions), Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

generate_question_field : Question -> Field
generate_question_field question = {
    id=(String.join "_" ["question", toString question.order])
  , editable=False
  , hover=False
  , field_type=QuestionField }

generate_answers : Int -> List Answer
generate_answers n = List.map (\i -> Answer Nothing Nothing "Click to write choice " False i "")
  <| List.range 1 n

toggleHover : Int -> Array Field -> (Array Field, String)
toggleHover i fields = case Array.get i fields of
  Just field -> case field.hover of
    True -> (Array.set i { field | hover = False } fields, field.id)
    _ -> (Array.set i { field | hover = True } fields, field.id)
  _ -> (fields, "")

toggleEditable : Int -> Array Field -> (Array Field, String)
toggleEditable i fields = case Array.get i fields of
   Just field -> case field.editable of
      True -> (Array.set i { field | editable = False, hover = False } fields, field.id)
      _ -> (Array.set i { field | editable = True, hover = False } fields, field.id)
   _ -> (fields, "")

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField field_type i -> case field_type of
      TextField -> let (fields, field_id) = (toggleEditable i model.text_fields) in
         ({ model | text_fields = fields }, selectAllInputText field_id )
      QuestionField -> let (fields, field_id) = (toggleEditable i model.question_fields) in
         ({ model | question_fields = fields }, selectAllInputText field_id )

    Hover field_type i -> case field_type of
      TextField -> let (fields, field_id) = (toggleHover i model.text_fields) in
         ({ model | text_fields = fields }, selectAllInputText field_id )
      QuestionField -> let (fields, field_id) = (toggleHover i model.question_fields) in
         ({ model | question_fields = fields }, selectAllInputText field_id )

    UpdateTitle title -> ({ model | text = { text | title = title }}, Cmd.none)
    UpdateSource source ->  ({ model | text = { text | source = source }}, Cmd.none)
    UpdateDifficulty difficulty -> ({ model | text = { text | difficulty = difficulty }}, Cmd.none)
    UpdateBody body -> ({ model | text = { text | body = body }}, Cmd.none)

    UpdateQuestionBody i question body -> ({
      model | questions = (Array.set i {
          question | body = body
        } model.questions)
      }, Cmd.none)


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

view_editable_answer : Array Field -> Int -> Answer -> List (Html Msg)
view_editable_answer fields i answer = [ div [] [] ]

edit_question : Field -> Question -> Int -> List (Html Msg)
edit_question question_field question i = [
      div [] [Html.input [attribute "type" "checkbox"] []]
      , Html.input [
          attribute "type" "text"
        , attribute "value" question.body
        , attribute "id" question_field.id
        , onInput (UpdateQuestionBody i question)
        , onBlur (ToggleEditableField QuestionField i) ] [ ] ] ++ (List.map (view_answer question) question.answers)

view_question : Field -> Question -> Int -> List (Html Msg)
view_question question_field question i = [
      div [] [Html.input [attribute "type" "checkbox"] []]
   ,  div [
          attribute "id" question_field.id
        , classList [("question_item", True), ("over", question_field.hover)]
        , onClick (ToggleEditableField QuestionField i)
        , onMouseOver (Hover QuestionField i)
        , onMouseLeave (Hover QuestionField i)
      ] [ Html.text question.body ]
 ] ++ (List.map (view_answer question) question.answers)


view_editable_question : Array Field -> Int -> Question -> List (Html Msg)
view_editable_question fields i question = let question_field = case Array.get i fields of
    Just field -> field
    _ -> (generate_question_field question) in case question_field.editable of
      True -> edit_question question_field question i
      _ -> view_question question_field question i

view_questions : Array Field -> Array Question -> Html Msg
view_questions fields questions = div [ classList [("question_section", True)] ] [
      div [ classList [("questions", True)] ]
      (  List.concat
      <| Array.toList
      <| Array.indexedMap (view_editable_question fields) questions
      )]

get_hover : Array Field -> Int -> Bool
get_hover fields i = case Array.get i fields of
  Just field -> field.hover
  Nothing -> False

hover_attrs : Array Field -> Int -> List (Attribute Msg)
hover_attrs fields i = [
    classList [ ("over", get_hover fields i) ]
  , onMouseOver (Hover TextField i)
  , onMouseLeave (Hover TextField i)]

text_property_attrs : Model -> Int -> List (Attribute Msg)
text_property_attrs model i = [onClick (ToggleEditableField TextField i)] ++ (hover_attrs model.text_fields i)

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
      , onBlur (ToggleEditableField TextField i) ] [ ]

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
      , onBlur (ToggleEditableField TextField i) ] [ ]

edit_difficulty : Model -> Int -> Html Msg
edit_difficulty model i = Html.div [] [
      Html.text "Difficulty:  "
    , Html.select [
         onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option (if v == model.text.difficulty then [attribute "selected" ""] else []) [Html.text v])
          question_difficulties
        )
       ]
  ]

view_body : Model -> Int -> Html Msg
view_body model i = Html.div (text_property_attrs model i) [
    Html.text "Text: "
  , Html.text model.text.body ]

edit_body : Model -> Int -> Html Msg
edit_body model i = Html.textarea [
        onInput UpdateBody
      , attribute "id" "body"
      , onBlur (ToggleEditableField TextField i) ] [ Html.text model.text.body ]

view_editable_field : Model -> Int -> (Model -> Int -> Html Msg) -> (Model -> Int -> Html Msg) -> Html Msg
view_editable_field model i view edit = case Array.get i model.text_fields of
   Just field -> case field.editable of
     True -> (edit model i)
     _ -> (view model i)
   _ -> (view model i)

view_create_text : Model -> Html Msg
view_create_text model = div [ classList [("text_properties", True)] ] [
      div [ classList [("text_property_items", True)] ] [
          view_editable_field model 0 view_title edit_title
        , view_editable_field model 1 view_source edit_source
        , view_editable_field model 2 edit_difficulty edit_difficulty
      ]
      , div [ classList [("body",True)] ]  [ view_editable_field model 3 view_body edit_body ]
  ]

view : Model -> Html Msg
view model = div [] [
      (view_header model)
    , (view_preview model)
    , (view_create_text model)
    , (view_questions model.question_fields model.questions)
  ]
