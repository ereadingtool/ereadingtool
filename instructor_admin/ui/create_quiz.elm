import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onMouseOut, onMouseLeave)

import Array exposing (Array)

import Model exposing (Text, Question, Answer, textsDecoder)

import Ports exposing (selectAllInputText)


type Field = Text TextField | Question QuestionField | Answer AnswerField

type Msg = ToggleEditableField Field | Hover Field | UnHover Field
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String
  | UpdateQuestionBody QuestionField String
  | UpdateAnswer QuestionField AnswerField String
  | AddQuestion

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
  , question_field_index : Int
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

add_new_question : Array QuestionField -> Array QuestionField
add_new_question fields = let arr_len = Array.length fields in
  Array.push (generate_question_field arr_len new_question) fields

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
  , answer = answer
  , question_field_index = i
  , index=j }


generate_answer : Int -> Answer
generate_answer i = {
    id=Nothing
  , question_id=Nothing
  , text=String.join " " ["Click to write choice", toString i]
  , correct=False
  , order=i
  , feedback="" }

generate_answers : Int -> Array Answer
generate_answers n =
     Array.fromList
  <| List.map generate_answer
  <| List.range 1 n

toggle_editable : { a | hover : Bool, index : Int, editable : Bool }
    -> Array { a | index : Int, editable : Bool, hover : Bool }
    -> Array { a | index : Int, editable : Bool, hover : Bool }
toggle_editable field fields =
  Array.set field.index { field |
    editable = (if field.editable then False else True), hover=False}
  fields

set_hover
    : { a | hover : Bool, index : Int }
    -> Bool
    -> Array { a | index : Int, hover : Bool }
    -> Array { a | index : Int, hover : Bool }
set_hover field hover fields = Array.set field.index { field | hover = hover } fields

update_answer : AnswerField -> Array QuestionField -> Array QuestionField
update_answer answer_field question_fields = case Array.get answer_field.question_field_index question_fields of
    Just question_field ->
      let new_question_field = { question_field
      | answer_fields = Array.set answer_field.index answer_field question_field.answer_fields } in
      Array.set new_question_field.index new_question_field question_fields
    _ -> question_fields

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField field -> case field of
      Text text_field -> ({ model | text_fields = toggle_editable text_field model.text_fields }
                     , selectAllInputText text_field.id )
      Question question_field -> ({ model | question_fields = toggle_editable question_field model.question_fields }
                         , selectAllInputText question_field.id )

      Answer answer_field ->
        let new_answer_field = { answer_field
          | editable = (if answer_field.editable then False else True)
          , hover = False } in
        ({ model | question_fields = update_answer new_answer_field model.question_fields}
         , selectAllInputText new_answer_field.id )

    Hover field -> case field of
      Text text_field -> ({ model | text_fields = set_hover text_field True model.text_fields }
                     , selectAllInputText text_field.id )
      Question question_field -> ({ model | question_fields = set_hover question_field True model.question_fields }
                         , selectAllInputText question_field.id )

      Answer answer_field -> let new_answer_field = { answer_field | hover = True } in
        ({ model | question_fields = update_answer new_answer_field model.question_fields}
         , selectAllInputText new_answer_field.id )

    UnHover field -> case field of
      Text text_field -> ({ model | text_fields = set_hover text_field False model.text_fields }
                     , selectAllInputText text_field.id )
      Question question_field -> ({ model | question_fields = set_hover question_field False model.question_fields }
                     , selectAllInputText question_field.id )

      Answer answer_field -> let new_answer_field = { answer_field | hover = False } in
        ({ model | question_fields = update_answer new_answer_field model.question_fields}
         , selectAllInputText new_answer_field.id )

    UpdateQuestionBody field body ->
      let question = field.question in
      let new_field = {field | question = {question | body = body} } in
        ({ model | question_fields = Array.set field.index new_field model.question_fields }, Cmd.none)

    UpdateAnswer question_field answer_field text ->
      let answer = answer_field.answer in
      let new_answer = { answer | text = text } in
      let new_answer_field = { answer_field | answer = new_answer } in
      let new_question_field = { question_field |
        answer_fields = Array.set answer_field.index new_answer_field question_field.answer_fields } in
        ({ model |
          question_fields = Array.set new_question_field.index new_question_field model.question_fields }, Cmd.none)

    UpdateTitle title -> ({ model | text = { text | title = title }}, Cmd.none)
    UpdateSource source ->  ({ model | text = { text | source = source }}, Cmd.none)
    UpdateDifficulty difficulty -> ({ model | text = { text | difficulty = difficulty }}, Cmd.none)
    UpdateBody body -> ({ model | text = { text | body = body }}, Cmd.none)

    AddQuestion -> ({model | question_fields = add_new_question model.question_fields }, Cmd.none)


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
    , onMouseLeave (UnHover <| Question question_field)
  ] [ Html.text question_field.question.body ]


view_answer : QuestionField -> AnswerField -> Html Msg
view_answer question_field answer_field = Html.span
  [  onClick (ToggleEditableField <| Answer answer_field)
   , onMouseOver (Hover <| Answer answer_field)
   , onMouseLeave (UnHover <| Answer answer_field) ]
  [ Html.text <| answer_field.answer.text ]

edit_answer : QuestionField -> AnswerField -> Html Msg
edit_answer question_field answer_field = Html.input [
      attribute "type" "text"
    , attribute "value" answer_field.answer.text
    , attribute "id" answer_field.id
    , onInput (UpdateAnswer question_field answer_field)
    , onBlur (ToggleEditableField <| Answer answer_field)
  ] [ ]

view_editable_answer : QuestionField -> AnswerField -> Html Msg
view_editable_answer question_field answer_field = div [
  classList [("answer_item", True)
            ,("over", answer_field.hover)] ] [
        Html.input [
            attribute "type" "radio"
          , attribute "id"
            (String.join "_" [
                "question"
              , (toString question_field.question.order)
              , "answer", toString answer_field.answer.order])
        ] []
     ,  (case answer_field.editable of
           True -> edit_answer question_field answer_field
           False -> view_answer question_field answer_field)
  ]

view_editable_question : QuestionField -> Html Msg
view_editable_question field = div [classList [("question", True)]] <| [
       div [] [ Html.input [attribute "type" "checkbox"] [] ]
       , (case field.editable of
          True -> edit_question field
          _ -> view_question field)
    ] ++ (Array.toList <| Array.map (view_editable_answer field) field.answer_fields)

view_add_question : Array QuestionField -> Html Msg
view_add_question fields = div [classList [("add_question", True)], onClick AddQuestion ] [ Html.text "Add question" ]

view_questions : Array QuestionField -> Html Msg
view_questions fields = div [ classList [("question_section", True)] ] <|
        (  Array.toList
        <| Array.map view_editable_question fields
        ) ++ [ (view_add_question fields) ]

get_hover : Array TextField -> Int -> Bool
get_hover fields i = case Array.get i fields of
  Just field -> field.hover
  Nothing -> False

hover_attrs : TextField -> List (Attribute Msg)
hover_attrs field = [
    classList [ ("over", field.hover) ]
  , onMouseOver (Hover <| Text field)
  , onMouseLeave (UnHover <| Text field)]

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
