module Text.Section.Component exposing
    ( TextSectionComponent
    , TextSectionField
    , add_answer
    , add_new_question
    , attributes
    , body
    , body_id
    , delete_answer
    , delete_question_field
    , delete_selected_question_fields
    , editable
    , emptyTextSectionComponent
    , fromTextSection
    , index
    , post_toggle_commands
    , question_fields
    , reinitialize_ck_editor
    , set_answer
    , set_answer_correct
    , set_answer_feedback
    , set_answer_text
    , set_field
    , set_field_value
    , set_index
    , set_question
    , switch_editable
    , text_field_id
    , text_section
    , toTextSection
    , toggle_question_menu
    , update_body
    , update_errors
    , update_question_field
    )

import Answer.Field
import Answer.Model
import Array exposing (Array)
import Field
import Ports exposing (ckEditor, ckEditorSetHtml)
import Question.Field exposing (QuestionField)
import Text.Section.Model exposing (TextSection)


type alias TextSectionField =
    Field.FieldAttributes { name : String }


type alias TextSectionFields =
    { body : TextSectionField }


type alias TextSectionComponentAttributes =
    { index : Int }


type TextSectionComponent
    = TextSectionComponent TextSection TextSectionComponentAttributes TextSectionFields (Array QuestionField)


type alias FieldName =
    String


generate_text_section_field_id : Int -> String -> String
generate_text_section_field_id i attr =
    String.join "_" [ "textsection", String.fromInt i, attr ]


generate_text_section_field_params : Int -> String -> TextSectionField
generate_text_section_field_params i attr =
    { id = generate_text_section_field_id i attr
    , input_id = String.join "_" [ generate_text_section_field_id i attr, "input" ]
    , editable = False
    , error_string = ""
    , error = False
    , name = attr
    , index = i
    }


generate_text_section_fields : Int -> TextSectionFields
generate_text_section_fields i =
    { body = generate_text_section_field_params i "body" }


fromTextSection : Int -> TextSection -> TextSectionComponent
fromTextSection i text =
    TextSectionComponent text { index = i } (generate_text_section_fields i) (Question.Field.fromQuestions i text.questions)


reinitialize_ck_editor : TextSectionComponent -> Cmd msg
reinitialize_ck_editor text_section_component =
    let
        t =
            text_section text_section_component

        body_field =
            body text_section_component
    in
    Cmd.batch [ ckEditor body_field.id, ckEditorSetHtml ( body_field.id, t.body ) ]


emptyTextSectionComponent : Int -> TextSectionComponent
emptyTextSectionComponent i =
    TextSectionComponent
        (Text.Section.Model.emptyTextSection i)
        { index = i }
        (generate_text_section_fields i)
        (Question.Field.initial_question_fields i)


switch_editable : TextSectionField -> TextSectionField
switch_editable text_field =
    let
        switch field =
            { field
                | editable =
                    if field.editable then
                        False

                    else
                        True
            }
    in
    switch text_field


update_errors : TextSectionComponent -> ( String, String ) -> TextSectionComponent
update_errors ((TextSectionComponent text attr fields questionFields) as textSection) ( field_id, field_error ) =
    {- error keys could be
          body
       || (question_i_answers)
       || (question_i_answer_j)
       || (question_i_answer_j_feedback)
    -}
    let
        error_key =
            String.split "_" field_id

        first_key =
            List.head error_key
    in
    case first_key of
        Just fst ->
            if List.member fst [ "body" ] then
                case get_field textSection fst of
                    Just field ->
                        set_field textSection (update_field_error field field_error)

                    Nothing ->
                        textSection
                -- no matching field name

            else
                -- update questions/answers errors
                TextSectionComponent text attr fields (Question.Field.update_errors questionFields ( field_id, field_error ))

        _ ->
            textSection



-- empty key


text_field_id : TextSectionField -> String
text_field_id text_field =
    text_field.id


editable : TextSectionField -> Bool
editable text_field =
    text_field.editable


post_toggle_commands : TextSectionField -> List (Cmd msg)
post_toggle_commands text_field =
    case text_field.name of
        "body" ->
            [ ckEditor text_field.id ]

        _ ->
            [ Cmd.none ]


body_id : TextSectionComponent -> String
body_id text_section_component =
    let
        body_field =
            body text_section_component
    in
    body_field.id


body : TextSectionComponent -> TextSectionField
body (TextSectionComponent text attr fields _) =
    fields.body


update_body : TextSectionComponent -> String -> TextSectionComponent
update_body (TextSectionComponent text attr fields questionFields) bdy =
    TextSectionComponent { text | body = bdy } attr fields questionFields


text_section : TextSectionComponent -> TextSection
text_section (TextSectionComponent textSection attr fields _) =
    textSection


attributes : TextSectionComponent -> TextSectionComponentAttributes
attributes (TextSectionComponent text attr fields _) =
    attr


index : TextSectionComponent -> Int
index textSection =
    let
        attrs =
            attributes textSection
    in
    attrs.index


set_index : TextSectionComponent -> Int -> TextSectionComponent
set_index (TextSectionComponent text attr fields questionFields) idx =
    let
        body_field =
            fields.body

        new_body_field =
            { body_field | id = generate_text_section_field_id idx "body" }
    in
    TextSectionComponent
        { text | order = idx }
        { attr | index = idx }
        { fields | body = new_body_field }
        questionFields


set_question : TextSectionComponent -> QuestionField -> TextSectionComponent
set_question (TextSectionComponent text attr fields questionFields) question_field =
    let
        question_index =
            Question.Field.index question_field
    in
    TextSectionComponent text attr fields (Array.set question_index question_field questionFields)


set_answer : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
set_answer (TextSectionComponent text attr fields questionFields) answer_field =
    TextSectionComponent text attr fields (Question.Field.set_answer_field questionFields answer_field)


set_answer_text : TextSectionComponent -> Answer.Field.AnswerField -> String -> TextSectionComponent
set_answer_text textSection answer_field answer_text =
    set_answer textSection (Answer.Field.set_answer_text answer_field answer_text)


set_answer_correct : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
set_answer_correct textSection answer_field =
    case Question.Field.question_field_for_answer (question_fields textSection) answer_field of
        Just question_field ->
            set_question textSection (Question.Field.set_answer_correct question_field answer_field)

        _ ->
            textSection


set_answer_feedback : TextSectionComponent -> Answer.Field.AnswerField -> String -> TextSectionComponent
set_answer_feedback textSection answer_field feedback =
    case Question.Field.question_field_for_answer (question_fields textSection) answer_field of
        Just question_field ->
            set_question textSection (Question.Field.set_answer_feedback question_field answer_field feedback)

        _ ->
            textSection



-- adds a new answer field after the given answer field


add_answer : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
add_answer text_section_component answer_field =
    let
        text_section_index =
            index text_section_component

        question_index =
            Answer.Field.question_index answer_field

        question_field =
            Array.get question_index (question_fields text_section_component)
    in
    case question_field of
        Just q_field ->
            let
                new_answer =
                    Answer.Model.generate_answer (Answer.Field.index answer_field + 1)

                new_answer_field =
                    Answer.Field.generate_answer_field text_section_index question_index new_answer.order new_answer
            in
            update_question_field text_section_component
                (Question.Field.add_answer_field q_field answer_field new_answer_field)

        Nothing ->
            text_section_component


delete_answer : TextSectionComponent -> Answer.Field.AnswerField -> TextSectionComponent
delete_answer text_section_component answer_field =
    let
        question_field =
            Array.get (Answer.Field.question_index answer_field) (question_fields text_section_component)
    in
    case question_field of
        Just field ->
            update_question_field text_section_component (Question.Field.delete_answer_field field answer_field)

        Nothing ->
            text_section_component


set_field_value : TextSectionComponent -> FieldName -> String -> TextSectionComponent
set_field_value (TextSectionComponent text attr fields questionFields) field_name value =
    case field_name of
        "body" ->
            TextSectionComponent { text | body = value } attr fields questionFields

        _ ->
            TextSectionComponent text attr fields questionFields


update_field_error : TextSectionField -> String -> TextSectionField
update_field_error text_field error_string =
    { text_field | error = True, error_string = error_string }


get_field : TextSectionComponent -> FieldName -> Maybe TextSectionField
get_field (TextSectionComponent text attr fields _) field_name =
    case field_name of
        "body" ->
            Just fields.body

        _ ->
            Nothing


set_field : TextSectionComponent -> TextSectionField -> TextSectionComponent
set_field ((TextSectionComponent text attr fields questionFields) as textSection) new_text_field =
    case new_text_field.name of
        "body" ->
            TextSectionComponent text attr { fields | body = new_text_field } questionFields

        _ ->
            textSection


question_fields : TextSectionComponent -> Array QuestionField
question_fields (TextSectionComponent text attr fields questionFields) =
    questionFields


update_question_field : TextSectionComponent -> QuestionField -> TextSectionComponent
update_question_field (TextSectionComponent text attr fields questionFields) question_field =
    TextSectionComponent text attr fields (Question.Field.update_question_field question_field questionFields)


delete_question_field : TextSectionComponent -> QuestionField -> TextSectionComponent
delete_question_field (TextSectionComponent text attr fields questionFields) question_field =
    TextSectionComponent text attr fields (Question.Field.delete_question_field question_field questionFields)


delete_selected_question_fields : TextSectionComponent -> TextSectionComponent
delete_selected_question_fields (TextSectionComponent text attr fields questionFields) =
    TextSectionComponent text attr fields (Question.Field.delete_selected questionFields)


add_new_question : TextSectionComponent -> TextSectionComponent
add_new_question (TextSectionComponent text attr fields questionFields) =
    TextSectionComponent text attr fields (Question.Field.add_new_question attr.index questionFields)


toggle_question_menu : TextSectionComponent -> QuestionField -> TextSectionComponent
toggle_question_menu textSection question_field =
    let
        visible =
            if Question.Field.menu_visible question_field then
                False

            else
                True
    in
    set_question textSection (Question.Field.set_menu_visible question_field visible)


toTextSection : TextSectionComponent -> TextSection
toTextSection text_section_component =
    let
        new_text_section =
            text_section text_section_component

        questions =
            Question.Field.toQuestions (question_fields text_section_component)
    in
    { new_text_section | questions = questions }
