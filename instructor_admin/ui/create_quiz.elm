import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onMouseOut, onMouseLeave)

import Array exposing (Array)

import Model exposing (Text, Question, Answer, textsDecoder)

import Ports exposing (selectAllInputText)


type Field = Text TextField | Question QuestionField | Answer AnswerField

type Msg = ToggleEditableField Field | Hover Field
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String
  | UpdateQuestionBody QuestionField String

type alias TextField = {
    id : String
  , editable : Bool
  , hover : Bool
  , index : Int }

type alias AnswerField = {
    id : String
  , editable : Bool
  , hover : Bool
  , answer : Answer
  , index : Int }

type alias QuestionField = {
    id : String
  , editable : Bool
  , hover : Bool
  , question : Question
  , answer_fields : Array AnswerField
  , index : Int }


type alias Model = {
    text : Text
  , text_fields : Array TextField
  , question_fields : Array QuestionField }

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
  , answers = generate_answers 4
  , question_type = "main_idea" }


question_difficulties : List (String, String)
question_difficulties = [
    ("intermediate_mid", "Intermediate-Mid")
  , ("intermediate_high", "Intermediate-High")
  , ("advanced_low", "Advanced-Low")
  , ("advanced_mid", "Advanced-Mid") ]


initial_questions : Array Question
initial_questions = Array.fromList [new_question]

init : (Model, Cmd Msg)
init = ({
        text=new_text
      , text_fields=(Array.fromList [
          {id="title", editable=False, hover=False, index=0}
        , {id="source", editable=False, hover=False, index=1}
        , {id="difficulty", editable=False, hover=False, index=2}
        , {id="body", editable=False, hover=False, index=3} ])
      , question_fields=(Array.indexedMap generate_question_field initial_questions)
  }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

generate_question_field : Int -> Question -> QuestionField
generate_question_field i question = {
    id=(String.join "_" ["question", toString i])
  , editable=False
  , hover=False
  , question=question
  , answer_fields=(Array.indexedMap (generate_answer_field i question) question.answers)
  , index=i }

generate_answer_field : Int -> Question -> Int -> Answer -> AnswerField
generate_answer_field i question j answer = {
    id=(String.join "_" ["question", toString i, "answer", toString j])
  , editable=False
  , hover=False
  , answer = generate_answer j
  , index=i }


generate_answer : Int -> Answer
generate_answer i = {
    id=Nothing
  , question_id=Nothing
  , text="Click to write choice "
  , correct=False
  , order=i
  , feedback="" }

generate_answers : Int -> Array Answer
generate_answers n =
     Array.fromList
  <| List.map generate_answer
  <| List.range 1 n

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField field_type -> case field_type of
      Text field -> let new_field = { field | editable = (if field.editable then False else True), hover=False} in
        ({ model |
          text_fields = Array.set field.index new_field model.text_fields }, selectAllInputText field.id )

      Question field -> let new_field = { field | editable = (if field.editable then False else True), hover=False } in
        ({ model |
          question_fields = Array.set field.index new_field model.question_fields }, selectAllInputText field.id )

      _ -> (model, Cmd.none)

    Hover field_type -> case field_type of
      Text field -> let new_field = { field | hover = (if field.hover then False else True) } in
        ({ model |
          text_fields = Array.set field.index new_field model.text_fields }, selectAllInputText field.id )

      Question field -> let new_field = { field | hover = (if field.hover then False else True) } in
        ({ model |
          question_fields = Array.set field.index new_field model.question_fields }, selectAllInputText field.id )

      _ -> (model, Cmd.none)

    UpdateQuestionBody field body ->
      let question = field.question in
      let new_field = {field | question = {question | body = body} } in
        ({ model | question_fields = Array.set field.index new_field model.question_fields }, Cmd.none)

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

edit_question : QuestionField -> Html Msg
edit_question question_field =
  Html.input [
      attribute "type" "text"
    , attribute "value" question_field.question.body
    , attribute "id" question_field.id
    , onInput (UpdateQuestionBody question_field)
    , onBlur (ToggleEditableField <| Question question_field)
  ] [ ]

view_question : QuestionField -> Html Msg
view_question question_field =
  div [
      attribute "id" question_field.id
    , classList [("question_item", True), ("over", question_field.hover)]
    , onClick (ToggleEditableField <| Question question_field)
    , onMouseOver (Hover <| Question question_field)
    , onMouseLeave (Hover <| Question question_field)
  ] [ Html.text question_field.question.body ]


view_editable_answer : Array AnswerField -> Int -> Answer -> List (Html Msg)
view_editable_answer fields i answer = [ div [] [] ]


view_editable_question : Int -> QuestionField -> List (Html Msg)
view_editable_question i field = [
       div [] [ Html.input [attribute "type" "checkbox"] [] ]
    ,  (case field.editable of
        True -> edit_question field
        _ -> view_question field)
    ] ++ (Array.toList <| Array.map (view_answer field.question) field.question.answers)

view_questions : Array QuestionField -> Html Msg
view_questions fields = div [ classList [("question_section", True)] ] [
      div [ classList [("questions", True)] ]
      (  List.concat
      <| Array.toList
      <| Array.indexedMap view_editable_question fields
      )]

get_hover : Array TextField -> Int -> Bool
get_hover fields i = case Array.get i fields of
  Just field -> field.hover
  Nothing -> False

hover_attrs : TextField -> List (Attribute Msg)
hover_attrs field = [
    classList [ ("over", field.hover) ]
  , onMouseOver (Hover <| Text field)
  , onMouseLeave (Hover <| Text field)]

text_property_attrs : TextField -> List (Attribute Msg)
text_property_attrs field = [onClick (ToggleEditableField <| Text field)] ++ (hover_attrs field)

view_title : Model -> TextField -> Html Msg
view_title model field = Html.div (text_property_attrs field) [
    Html.text "Title: "
  , Html.text model.text.title
  ]

edit_title : Model -> TextField -> Html Msg
edit_title model field = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.title
      , attribute "id" "title"
      , onInput UpdateTitle
      , onBlur (ToggleEditableField <| Text field) ] [ ]

view_source : Model -> TextField -> Html Msg
view_source model field = Html.div (text_property_attrs field) [
     Html.text "Source: "
   , Html.text model.text.source
  ]

edit_source : Model -> TextField -> Html Msg
edit_source model field = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.source
      , attribute "id" "source"
      , onInput UpdateSource
      , onBlur (ToggleEditableField <| Text field) ] [ ]

edit_difficulty : Model -> TextField -> Html Msg
edit_difficulty model field = Html.div [] [
      Html.text "Difficulty:  "
    , Html.select [
         onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option (if v == model.text.difficulty then [attribute "selected" ""] else []) [Html.text v])
          question_difficulties
        )
       ]
  ]

view_body : Model -> TextField -> Html Msg
view_body model field = Html.div (text_property_attrs field) [
    Html.text "Text: "
  , Html.text model.text.body ]

edit_body : Model -> TextField -> Html Msg
edit_body model field = Html.textarea [
        onInput UpdateBody
      , attribute "id" field.id
      , onBlur (ToggleEditableField <| Text field) ] [ Html.text model.text.body ]

view_editable_field : Model -> Int -> (TextField -> Html Msg) -> (TextField -> Html Msg) -> Html Msg
view_editable_field model i view edit = case Array.get i model.text_fields of
   Just field -> case field.editable of
     True -> edit field
     _ -> view field
   _ -> Html.text ""

view_create_text : Model -> Html Msg
view_create_text model = div [ classList [("text_properties", True)] ] [
      div [ classList [("text_property_items", True)] ] [
          view_editable_field model 0 (view_title model) (edit_title model)
        , view_editable_field model 1 (view_source model) (edit_source model)
        , view_editable_field model 2 (edit_difficulty model) (edit_difficulty model)
      ]
      , div [ classList [("body",True)] ]  [ view_editable_field model 3 (view_body model) (edit_body model) ]
  ]

view : Model -> Html Msg
view model = div [] [
      (view_header model)
    , (view_preview model)
    , (view_create_text model)
    , (view_questions model.question_fields)
  ]
