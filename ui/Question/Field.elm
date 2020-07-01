module Question.Field exposing
    ( QuestionField
    , QuestionType(..)
    , add_answer_field
    , add_new_question
    , answers
    , attributes
    , delete_answer_field
    , delete_question
    , delete_question_field
    , delete_selected
    , editable
    , error
    , fromQuestions
    , generate_question_field
    , get_question_field
    , id
    , index
    , initial_question_fields
    , menu_visible
    , question
    , question_field_for_answer
    , set_answer_correct
    , set_answer_feedback
    , set_answer_field
    , set_answers
    , set_menu_visible
    , set_question_body
    , set_question_type
    , set_selected
    , switch_editable
    , toQuestions
    , update_errors
    , update_question
    , update_question_field
    )

import Answer.Field exposing (AnswerField, generate_answer_field)
import Array exposing (Array)
import Field
import Question.Model exposing (Question)


type alias QuestionFieldAttributes =
    Field.FieldAttributes
        { menu_visible : Bool
        , selected : Bool
        }


type QuestionType
    = MainIdea
    | Detail


type QuestionField
    = QuestionField Question (Field.FieldAttributes QuestionFieldAttributes) (Array AnswerField)


toQuestions : Array QuestionField -> Array Question
toQuestions question_fields =
    Array.map toQuestion question_fields


toQuestion : QuestionField -> Question
toQuestion question_field =
    let
        new_question =
            question question_field

        new_answers =
            Answer.Field.toAnswers (answers question_field)
    in
    { new_question | answers = new_answers }


fromQuestions : Int -> Array Question -> Array QuestionField
fromQuestions text_index questions =
    Array.indexedMap (generate_question_field text_index) questions


generate_question_field : Int -> Int -> Question -> QuestionField
generate_question_field text_index questnIdx questn =
    let
        questionFieldId =
            String.join "_" [ "textsection", String.fromInt text_index, "question", String.fromInt questnIdx ]
    in
    QuestionField questn
        { id = questionFieldId
        , input_id = String.join "_" [ questionFieldId, "input" ]
        , editable = False
        , menu_visible = False
        , selected = False
        , error_string = ""
        , error = False
        , index = questnIdx
        }
        (Array.indexedMap (Answer.Field.generate_answer_field text_index questnIdx) questn.answers)


add_new_question : Int -> Array QuestionField -> Array QuestionField
add_new_question text_index fields =
    let
        new_question_index =
            Array.length fields
    in
    Array.push
        (generate_question_field text_index new_question_index (Question.Model.new_question new_question_index))
        fields


update_error : QuestionField -> String -> QuestionField
update_error (QuestionField questn attr answrs) error_string =
    QuestionField questn { attr | error = True, error_string = error_string } answrs


update_errors : Array QuestionField -> ( String, String ) -> Array QuestionField
update_errors question_fields ( field_id, field_error ) =
    let
        error_key =
            String.split "_" field_id
    in
    case error_key of
        "question" :: questnIdx :: "answer" :: answer_index :: feedback ->
            case String.toInt questnIdx of
                Ok i ->
                    case String.toInt answer_index of
                        Ok j ->
                            case get_question_field question_fields i of
                                Just question_field ->
                                    case Answer.Field.get_answer_field (answers question_field) j of
                                        Just answer_field ->
                                            set_answer_field question_fields
                                                (if List.isEmpty feedback then
                                                    Answer.Field.update_error answer_field field_error

                                                 else
                                                    Answer.Field.update_feedback_error answer_field field_error
                                                )

                                        Nothing ->
                                            question_fields

                                -- answer field does not exist
                                Nothing ->
                                    question_fields

                        -- question field does not exist
                        _ ->
                            question_fields

                -- not a valid answer index
                _ ->
                    question_fields

        -- not a valid question index
        "question" :: questnIdx :: field :: [] ->
            case String.toInt questnIdx of
                Ok i ->
                    case get_question_field question_fields i of
                        Just question_field ->
                            update_question_field (update_error question_field field_error) question_fields

                        _ ->
                            question_fields

                -- question field not present
                _ ->
                    question_fields

        -- not a valid question index
        _ ->
            question_fields



-- not a valid error key


get_question_field : Array QuestionField -> Int -> Maybe QuestionField
get_question_field question_fields idx =
    Array.get idx question_fields


set_answer_field : Array QuestionField -> AnswerField -> Array QuestionField
set_answer_field question_fields answer_field =
    let
        questnIdx =
            Answer.Field.question_index answer_field

        answer_index =
            Answer.Field.index answer_field
    in
    case Array.get questnIdx question_fields of
        Just (QuestionField questn attr answrs) ->
            Array.set questnIdx (QuestionField questn attr (Array.set answer_index answer_field answrs)) question_fields

        _ ->
            question_fields


set_answer_feedback : QuestionField -> AnswerField -> String -> QuestionField
set_answer_feedback (QuestionField questn attr answrs) answer_field feedback =
    let
        idx =
            Answer.Field.index answer_field

        new_answer_field =
            Answer.Field.set_answer_feedback answer_field feedback
    in
    QuestionField questn attr (Array.set idx new_answer_field answrs)


set_answer_correct : QuestionField -> AnswerField -> QuestionField
set_answer_correct (QuestionField questn attr answrs) answer_field =
    let
        answer_index =
            Answer.Field.index answer_field

        correct =
            Answer.Field.set_answer_correct

        idx =
            Answer.Field.index
    in
    QuestionField questn
        attr
        (Array.map
            (\a ->
                if idx a == answer_index then
                    correct a True

                else
                    correct a False
            )
            answrs
        )


question_field_for_answer : Array QuestionField -> AnswerField -> Maybe QuestionField
question_field_for_answer question_fields answer_field =
    let
        questnIdx =
            Answer.Field.question_index answer_field
    in
    Array.get questnIdx question_fields


question_index : QuestionField -> Int
question_index (QuestionField _ attr _) =
    attr.index


question : QuestionField -> Question
question (QuestionField questn _ _) =
    questn


update_question : QuestionField -> Question -> QuestionField
update_question (QuestionField questn attr answrs) new_question =
    QuestionField new_question attr answrs


error : QuestionField -> Bool
error question_field =
    let
        attrs =
            attributes question_field
    in
    attrs.error


delete_question : Int -> Array QuestionField -> Array QuestionField
delete_question idx fields =
    Array.indexedMap
        (\i (QuestionField questn attr answer_fields) ->
            QuestionField questn
                { attr | index = i }
                (Array.map (\answer_field -> Answer.Field.update_question_index answer_field i) answer_fields)
        )
    <|
        Array.filter (\field -> question_index field /= idx) fields


update_question_field : QuestionField -> Array QuestionField -> Array QuestionField
update_question_field new_question_field question_fields =
    Array.set (question_index new_question_field) new_question_field question_fields


initial_question_fields : Int -> Array QuestionField
initial_question_fields text_index =
    Array.indexedMap (generate_question_field text_index) Question.Model.initial_questions


set_question_type : QuestionField -> QuestionType -> QuestionField
set_question_type (QuestionField questn attr answer_fields) question_type =
    let
        q_type =
            case question_type of
                MainIdea ->
                    "main_idea"

                Detail ->
                    "detail"
    in
    QuestionField { questn | question_type = q_type } attr answer_fields


switch_editable : QuestionField -> QuestionField
switch_editable (QuestionField questn attr answer_fields) =
    QuestionField questn
        { attr
            | editable =
                if attr.editable then
                    False

                else
                    True
        }
        answer_fields


menu_visible : QuestionField -> Bool
menu_visible question_field =
    let
        attrs =
            attributes question_field
    in
    attrs.menu_visible


set_question_body : QuestionField -> String -> QuestionField
set_question_body (QuestionField questn attr answer_fields) value =
    QuestionField { questn | body = value } { attr | error = False } answer_fields


set_menu_visible : QuestionField -> Bool -> QuestionField
set_menu_visible (QuestionField questn attr answer_fields) visible =
    QuestionField questn { attr | menu_visible = visible } answer_fields


set_selected : QuestionField -> Bool -> QuestionField
set_selected (QuestionField questn attr answer_fields) selected =
    QuestionField questn { attr | selected = selected } answer_fields


delete_selected : Array QuestionField -> Array QuestionField
delete_selected question_fields =
    Array.filter
        (\q ->
            let
                q_attrs =
                    attributes q
            in
            not q_attrs.selected
        )
        question_fields


attributes : QuestionField -> QuestionFieldAttributes
attributes (QuestionField _ attr answer_fields) =
    attr


delete_question_field : QuestionField -> Array QuestionField -> Array QuestionField
delete_question_field question_field question_fields =
    (index >> delete_question) question_field question_fields


add_answer_field : QuestionField -> AnswerField -> AnswerField -> QuestionField
add_answer_field question_field answer_field new_answer_field =
    let
        new_answer_fields =
            Answer.Field.add_answer (answers question_field) answer_field new_answer_field
    in
    set_answers question_field new_answer_fields


delete_answer_field : QuestionField -> AnswerField -> QuestionField
delete_answer_field question_field answer_field =
    let
        new_answer_fields =
            Answer.Field.delete_answer (answers question_field) answer_field
    in
    set_answers question_field new_answer_fields


index : QuestionField -> Int
index question_field =
    let
        attrs =
            attributes question_field
    in
    attrs.index


id : QuestionField -> String
id question_field =
    let
        attrs =
            attributes question_field
    in
    attrs.id


editable : QuestionField -> Bool
editable question_field =
    let
        attrs =
            attributes question_field
    in
    attrs.editable


answers : QuestionField -> Array AnswerField
answers (QuestionField _ _ answer_fields) =
    answer_fields


set_answers : QuestionField -> Array AnswerField -> QuestionField
set_answers (QuestionField questn attr answer_fields) new_answer_fields =
    QuestionField questn attr new_answer_fields
