import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Array exposing (Array)

import Http
import HttpHelpers exposing (post_with_headers)

import Model exposing (Text, emptyText, TextDifficulty, Question, Answer, textsDecoder, textEncoder, textDecoder,
  textDifficultyDecoder, textCreateRespDecoder, decodeCreateRespErrors, TextCreateRespError, TextCreateResp)

import Dict

import Ports exposing (selectAllInputText, ckEditor, ckEditorUpdate)

import Config exposing (text_api_endpoint)

import Flags exposing (CSRFToken, Flags)

import Debug

type Field = Text TextField | Question QuestionField | Answer AnswerField

type Msg = ToggleEditableField Field | Hover Field | UnHover Field | ToggleQuestionMenu QuestionField
  | UpdateTitle String
  | UpdateSource String
  | UpdateDifficulty String
  | UpdateBody String
  | UpdateAuthor String
  | UpdateQuestionField QuestionField
  | UpdateQuestionBody QuestionField String
  | UpdateAnswerText QuestionField AnswerField String
  | UpdateAnswerCorrect QuestionField AnswerField Bool
  | UpdateAnswerFeedback QuestionField AnswerField String
  | AddQuestion
  | DeleteQuestion Int
  | UpdateTextDifficultyOptions (Result Http.Error (List TextDifficulty))
  | SubmitQuiz
  | Submitted (Result Http.Error TextCreateResp)

type alias TextField = {
    id : String
  , editable : Bool
  , hover : Bool
  , index : Int
  , error : Bool }

type alias AnswerFeedbackField = {
    id : String
  , editable : Bool
  , error : Bool }

type alias AnswerField = {
    id : String
  , editable : Bool
  , hover : Bool
  , answer : Answer
  , question_field_index : Int
  , index : Int
  , error: Bool
  , feedback_field : AnswerFeedbackField }

type alias QuestionField = {
    id : String
  , editable : Bool
  , hover : Bool
  , question : Question
  , answer_fields : Array AnswerField
  , menu_visible : Bool
  , index : Int
  , error : Bool }


type alias Model = {
    text : Text
  , flags : Flags
  , success_msg : Maybe String
  , error_msg : Maybe TextCreateRespError
  , text_fields : Array TextField
  , question_difficulties : List TextDifficulty
  , question_fields : Array QuestionField }

type alias Filter = List String

new_question : Int -> Question
new_question i = {
    id = Nothing
  , text_id = Nothing
  , created_dt = Nothing
  , modified_dt = Nothing
  , body = "Click to write the question text."
  , order = i
  , answers = generate_answers 4
  , question_type = "main_idea" }

initial_questions : Array Question
initial_questions = Array.fromList [(new_question 0)]

init : Flags -> (Model, Cmd Msg)
init flags = ({
        text=emptyText
      , error_msg=Nothing
      , success_msg=Nothing
      , flags=flags
      , text_fields=(Array.fromList [
          {id="title", editable=False, hover=False, index=0, error=False}
        , {id="source", editable=False, hover=False, index=1, error=False}
        , {id="difficulty", editable=False, hover=False, index=2, error=False}
        , {id="author", editable=False, hover=False, index=3, error=False}
        , {id="body", editable=False, hover=False, index=4, error=False} ])
      , question_fields=(Array.indexedMap generate_question_field initial_questions)
      , question_difficulties=[]
  }, retrieveTextDifficultyOptions)

retrieveTextDifficultyOptions : Cmd Msg
retrieveTextDifficultyOptions =
  let request = Http.get (String.join "?" [text_api_endpoint, "difficulties=list"]) textDifficultyDecoder in
    Http.send UpdateTextDifficultyOptions request

subscriptions : Model -> Sub Msg
subscriptions model =
  ckEditorUpdate UpdateBody

add_new_question : Array QuestionField -> Array QuestionField
add_new_question fields = let arr_len = Array.length fields in
  Array.push (generate_question_field arr_len (new_question arr_len)) fields

delete_question : Int -> Array QuestionField -> Array QuestionField
delete_question index fields =
     Array.indexedMap (\i field ->
       { field | index = i
       , answer_fields = Array.map (\a -> {a | question_field_index = i }) field.answer_fields
     })
  <| Array.filter (\field -> field.index /= index) fields

generate_question_field : Int -> Question -> QuestionField
generate_question_field i question = {
    id = (String.join "_" ["question", toString i])
  , editable = False
  , hover = False
  , question = question
  , answer_fields = (Array.indexedMap (generate_answer_field i question) question.answers)
  , menu_visible = True
  , index = i
  , error = False }

generate_answer_feedback_field : String -> AnswerFeedbackField
generate_answer_feedback_field id = {
    id = id
  , editable = False
  , error = False }

generate_answer_field : Int -> Question -> Int -> Answer -> AnswerField
generate_answer_field i question j answer =
  let answer_id = String.join "_" ["question", toString i, "answer", toString j] in {
    id = answer_id
  , editable = False
  , hover = False
  , answer = answer
  , question_field_index = i
  , index = j
  , error = False
  , feedback_field = (generate_answer_feedback_field <| String.join "_" [answer_id, "feedback"]) }

generate_answer : Int -> Answer
generate_answer i = {
    id=Nothing
  , question_id=Nothing
  , text=String.join " " ["Click to write choice", toString (i+1)]
  , correct=False
  , order=i
  , feedback="" }

generate_answers : Int -> Array Answer
generate_answers n =
     Array.fromList
  <| List.map generate_answer
  <| List.range 0 (n-1)

toggle_editable : { a | hover : Bool, index : Int, editable : Bool, error: Bool }
    -> Array { a | index : Int, editable : Bool, hover : Bool, error: Bool }
    -> Array { a | index : Int, editable : Bool, hover : Bool, error: Bool }
toggle_editable field fields =
  Array.set field.index { field |
      editable = (if field.editable then False else True)
    , hover=False
    , error=False }
  fields

set_hover
    : { a | hover : Bool, index : Int }
    -> Bool
    -> Array { a | index : Int, hover : Bool }
    -> Array { a | index : Int, hover : Bool }
set_hover field hover fields = Array.set field.index { field | hover = hover } fields

update_error : (String, String) -> Model -> Model
update_error (field_id, field_error) model =
  -- error keys can be one of: "question_n" | "text_(body|title|source|author)" | "question_n_answer_n"
  let split_id = String.split "_" field_id in case split_id of
    ["question", i, "answer", j, "feedback"] -> case (String.toInt i) of
      Ok i -> case Array.get i model.question_fields of
        Just question_field -> case (String.toInt j) of
          Ok j -> case Array.get j question_field.answer_fields of
            Just answer_field -> let feedback_field = (Debug.log "error on feedback" answer_field.feedback_field) in
              { model | question_fields =
                update_answer { answer_field | editable = True,
                  feedback_field = { feedback_field | error = True, editable = True }  } model.question_fields }
            _ -> Debug.log (String.join " " ["couldnt find answer field", (toString j), "from server"]) model
          _ -> Debug.log (String.join " " ["couldnt parse str ", j, "from server"]) model
        _ -> Debug.log (String.join " " ["couldnt find question field", (toString i), "from server"]) model
      _ -> Debug.log (String.join " " ["couldnt parse str ", i, "from server"]) model
    ["question", i] -> Debug.log "question" model
    ["text", id] -> Debug.log "text" model
    _ -> Debug.log "couldnt parse errors from server" model

update_errors : Model -> TextCreateRespError -> Model
update_errors model errors =
  List.foldr update_error model (Dict.toList errors)

update_answer : AnswerField -> Array QuestionField -> Array QuestionField
update_answer answer_field question_fields =
  case Array.get answer_field.question_field_index question_fields of
    Just question_field ->
      let new_question_field = { question_field
      | answer_fields = Array.set answer_field.index answer_field question_field.answer_fields } in
      Array.set new_question_field.index new_question_field question_fields
    _ -> question_fields

update_question_field : QuestionField -> Array QuestionField -> Array QuestionField
update_question_field new_question_field question_fields =
  Array.set new_question_field.index new_question_field question_fields

post_toggle_field : { a | id: String, hover : Bool, index : Int, editable : Bool } -> Cmd Msg
post_toggle_field field = if not field.editable then (selectAllInputText field.id) else Cmd.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = let text = model.text in
  case msg of
    ToggleEditableField field -> case field of
      Text text_field -> case text_field.id of
        "body" -> ({ model | text_fields = toggle_editable text_field model.text_fields }
                     , Cmd.batch [(ckEditor text_field.id), (post_toggle_field text_field)] )
        _ -> ({ model | text_fields = toggle_editable text_field model.text_fields }
                     , post_toggle_field text_field)

      Question question_field -> ({ model | question_fields = toggle_editable question_field model.question_fields }
                         , post_toggle_field question_field)
      Answer answer_field ->
        let answer_feedback_field = answer_field.feedback_field in
        let new_answer_feedback_field = {answer_feedback_field | error = False } in
        ({ model | question_fields = update_answer { answer_field
          | editable = (if answer_field.editable then False else True)
          , hover = False
          , feedback_field = new_answer_feedback_field
          , error = False } model.question_fields}
         , post_toggle_field answer_field )

    Hover field -> case field of
      Text text_field -> ({ model | text_fields = set_hover text_field True model.text_fields }
                     , Cmd.none )
      Question question_field -> ({ model | question_fields = set_hover question_field True model.question_fields }
                         , Cmd.none )

      Answer answer_field -> let new_answer_field = { answer_field | hover = True } in
        ({ model | question_fields = update_answer new_answer_field model.question_fields}
         , Cmd.none )

    UnHover field -> case field of
      Text text_field -> ({ model | text_fields = set_hover text_field False model.text_fields }
                     , Cmd.none )
      Question question_field -> ({ model | question_fields = set_hover question_field False model.question_fields }
                     , Cmd.none )

      Answer answer_field -> let new_answer_field = { answer_field | hover = False } in
        ({ model | question_fields = update_answer new_answer_field model.question_fields}
         , Cmd.none )

    UpdateQuestionBody field body ->
      let question = field.question in
      let new_field = {field | question = {question | body = body} } in
        ({ model | question_fields = update_question_field new_field model.question_fields }, Cmd.none)

    UpdateQuestionField new_field ->
        ({ model | question_fields = update_question_field new_field model.question_fields }, Cmd.none)

    UpdateAnswerText question_field answer_field text ->
      let answer = answer_field.answer in
      let new_answer = { answer | text = text } in
        ({ model | question_fields =
          update_answer { answer_field | answer = new_answer } model.question_fields }, Cmd.none)

    UpdateAnswerCorrect question_field answer_field correct ->
      let answer = answer_field.answer in
      let new_answer = { answer | correct = correct } in
        ({ model | question_fields =
          update_answer { answer_field | answer = new_answer } model.question_fields }, Cmd.none)

    UpdateAnswerFeedback question_field answer_field feedback ->
      let answer = answer_field.answer in
      let new_answer = { answer | feedback = feedback } in
        ({ model | question_fields =
          update_answer { answer_field | answer = new_answer } model.question_fields }, Cmd.none)


    UpdateTitle title -> ({ model | text = { text | title = title }}, Cmd.none)
    UpdateSource source ->  ({ model | text = { text | source = source }}, Cmd.none)
    UpdateDifficulty difficulty -> ({ model | text = { text | difficulty = difficulty }}, Cmd.none)
    UpdateBody body -> ({ model | text = { text | body = body }}, Cmd.none)
    UpdateAuthor author -> ({ model | text = { text | author = author }}, Cmd.none)

    AddQuestion -> ({model | question_fields = add_new_question model.question_fields }, Cmd.none)
    DeleteQuestion index -> ({model | question_fields = delete_question index model.question_fields }, Cmd.none)

    SubmitQuiz -> let questions = Array.map (\q_field ->
      let answer_fields = q_field.answer_fields in
      let question = q_field.question in
       { question | answers = Array.map (\a_field -> a_field.answer) q_field.answer_fields }) model.question_fields in
       ({ model |
           error_msg = Nothing
         , success_msg = Nothing }, post_text model.flags.csrftoken model.text questions)

    Submitted (Ok text_create_resp) -> case text_create_resp.id of
       Just text_id -> ({ model
         | success_msg = Just <| String.join " " <| [" success!", toString text_id]}, Cmd.none)
       _ -> (model, Cmd.none)

    Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (decodeCreateRespErrors (Debug.log "errors" resp.body)) of
        Ok errors -> (update_errors model (Debug.log "displaying validations" errors), Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)

    ToggleQuestionMenu field ->
      let new_field = { field | menu_visible = (if field.menu_visible then False else True) } in
        ({ model | question_fields = update_question_field new_field model.question_fields }, Cmd.none)

    UpdateTextDifficultyOptions (Ok difficulties) ->
      ({ model | question_difficulties = difficulties }, Cmd.none)
    -- handle user-friendly msgs
    UpdateTextDifficultyOptions (Err _) ->
      (model, Cmd.none)

post_text : CSRFToken -> Text -> Array Question -> Cmd Msg
post_text csrftoken text questions =
  let encoded_text = textEncoder text questions in
  let req =
    post_with_headers text_api_endpoint [Http.header "X-CSRFToken" csrftoken] (Http.jsonBody encoded_text)
    <| textCreateRespDecoder
  in
    Http.send Submitted req

main : Program Flags Model Msg
main =
  Html.programWithFlags
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
             Html.a [attribute "href" "/admin"] [ Html.text "Quizzes" ]
          ]
        ]
    ]

view_preview : Model -> Html Msg
view_preview model =
    div [ classList [("preview", True)] ] [
      div [ classList [("preview_menu", True)] ] [
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
  ] [
       Html.text question_field.question.body
  ]

view_answer_feedback : QuestionField -> AnswerField -> List (Html Msg)
view_answer_feedback question_field answer_field = if not (String.isEmpty answer_field.answer.feedback)
  then
    [ Html.div [classList [("answer_feedback", True)] ] [ Html.text answer_field.answer.feedback ] ]
  else
    []

view_answer : QuestionField -> AnswerField -> Html Msg
view_answer question_field answer_field = Html.span
  [  onClick (ToggleEditableField <| Answer answer_field)
   , onMouseOver (Hover <| Answer answer_field)
   , onMouseLeave (UnHover <| Answer answer_field) ] <|
  [   Html.text answer_field.answer.text ] ++ (view_answer_feedback question_field answer_field)

edit_answer_feedback : QuestionField -> AnswerField -> Html Msg
edit_answer_feedback question_field answer_field = Html.div [] [
      Html.textarea [
          attribute "id" answer_field.feedback_field.id
        , onBlur (ToggleEditableField <| Answer answer_field)
        , onInput (UpdateAnswerFeedback question_field answer_field)
        , attribute "placeholder" "Give some feedback."
        , classList [ ("answer_feedback", True), ("input_error", answer_field.feedback_field.error) ]
      ] [Html.text answer_field.answer.feedback]
    ]

edit_answer : QuestionField -> AnswerField -> Html Msg
edit_answer question_field answer_field =
  let answer_feedback_field_id = String.join "_" [answer_field.id, "feedback"]
   in Html.span [] [
    Html.input [
        attribute "type" "text"
      , attribute "value" answer_field.answer.text
      , attribute "id" answer_field.id
      , onInput (UpdateAnswerText question_field answer_field)
      , classList [ ("input_error", answer_field.error) ]
    ] []
  , (edit_answer_feedback question_field answer_field)
  ]

view_editable_answer : QuestionField -> AnswerField -> Html Msg
view_editable_answer question_field answer_field = div [
  classList [("answer_item", True)
            ,("over", answer_field.hover)] ] [
        Html.input [
            attribute "type" "radio"
          , attribute "name" (String.join "_" [
                "question"
              , (toString question_field.question.order), "correct_answer"])
          , onCheck (UpdateAnswerCorrect question_field answer_field)
        ] []
     ,  (case answer_field.editable of
           True -> edit_answer question_field answer_field
           False -> view_answer question_field answer_field)
  ]

view_delete_menu_item : QuestionField -> Html Msg
view_delete_menu_item field =
    Html.span [onClick (DeleteQuestion field.index)] [ Html.text "Delete" ]

view_question_type_menu_item : QuestionField -> Html Msg
view_question_type_menu_item field = let question = field.question in
  Html.div [] [
      (if question.question_type == "main_idea" then
        Html.strong [] [ Html.text "Main Idea" ]
       else
        Html.span [
          onClick (UpdateQuestionField { field | question = { question | question_type = "main_idea" } })
        ] [ Html.text "Main Idea" ])
    , Html.text " | "
    , (if question.question_type == "detail" then
        Html.strong [] [ Html.text "Detail" ]
       else
        Html.span [
          onClick (UpdateQuestionField { field | question = { question | question_type = "detail" } })
        ] [ Html.text "Detail" ])
  ]

view_menu_items : QuestionField -> List (Html Msg)
view_menu_items field = List.map (\html -> div [attribute "class" "question_menu_item"] [html]) [
      (view_delete_menu_item field)
    , (view_question_type_menu_item field)
  ]

view_question_menu : QuestionField -> List (Html Msg)
view_question_menu field = [
    div [ classList [("question_menu", True)] ] [
        Html.div [] [
          Html.img [
              attribute "src" "/static/img/action_arrow.svg"
            , onClick (ToggleQuestionMenu <| field)
          ] []
        ], Html.div [
          classList [("question_menu_overlay", True), ("hidden", field.menu_visible)]
        ] (view_menu_items field)
    ]
  ]

view_editable_question : QuestionField -> Html Msg
view_editable_question field = div [classList [("question", True)]] <| [
       div [] [ Html.input [attribute "type" "checkbox"] [] ]
       , (case field.editable of
          True -> edit_question field
          _ -> view_question field)
    ] ++ (view_question_menu field) ++
    (Array.toList <| Array.map (view_editable_answer field) field.answer_fields)

view_add_question : Array QuestionField -> Html Msg
view_add_question fields = div [classList [("add_question", True)], onClick AddQuestion ] [ Html.text "Add question" ]

view_questions : Array QuestionField -> Html Msg
view_questions fields = div [ classList [("question_section", True)] ] <|
        (  Array.toList
        <| Array.map view_editable_question fields
        ) ++ [ (view_add_question fields) ]

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
          Html.option ([attribute "value" k] ++ (if v == model.text.difficulty then [attribute "selected" ""] else []))
           [ Html.text v ]) model.question_difficulties)
       ]
  ]

view_body : Model -> TextField -> Html Msg
view_body model field = Html.div (text_property_attrs field) [
    Html.text "Text: "
  , Html.text model.text.body ]

edit_body : Model -> TextField -> Html Msg
edit_body model field = Html.textarea [
        onInput UpdateBody
      , attribute "id" field.id ] [ Html.text model.text.body ]

view_author : Model -> TextField -> Html Msg
view_author model field = Html.div (text_property_attrs field) [
    Html.text "Author: "
  , Html.text model.text.author ]

edit_author : Model -> TextField -> Html Msg
edit_author model field = Html.input [
        attribute "type" "text"
      , attribute "value" model.text.author
      , attribute "id" "author"
      , onInput UpdateAuthor
      , onBlur (ToggleEditableField <| Text field) ] [ ]

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
        , view_editable_field model 3 (view_author model) (edit_author model)
      ]
      , div [ classList [("body",True)] ]  [ view_editable_field model 4 (view_body model) (edit_body model) ]
  ]

view_msg : Maybe TextCreateRespError -> Html Msg
view_msg msg = case msg of
  Just err -> Html.text <| toString err
  _ -> Html.text ""


view_success_msg : Maybe String -> Html Msg
view_success_msg msg = let msg_str = (case msg of
        Just str ->
          String.join " " [" ", str]
        _ -> "") in Html.text msg_str


view_submit : Model -> Html Msg
view_submit model = Html.div [classList [("submit_section", True)]] [
    Html.div [attribute "class" "submit", onClick SubmitQuiz] [
        Html.text "Create Quiz "
      , view_msg model.error_msg
      , view_success_msg model.success_msg
    ]
  ]

view : Model -> Html Msg
view model = div [] [
      (view_header model)
    , (view_preview model)
    , (view_create_text model)
    , (view_questions model.question_fields)
    , (view_submit model)
  ]
