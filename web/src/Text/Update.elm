module Text.Update exposing (Field(..), Msg(..), update)

import Answer.Field exposing (AnswerField)
import Ports exposing (CKEditorID, CKEditorText, selectAllInputText)
import Question.Field exposing (QuestionField)
import Text.Component exposing (TextComponent)
import Text.Section.Component exposing (TextSectionComponent)
import Text.Section.Component.Group


type Field
    = Text Text.Section.Component.TextSectionField
    | Question QuestionField
    | Answer AnswerField


type Msg
    = -- text msgs
      UpdateTextValue TextSectionComponent String String
    | AddTextSection
    | DeleteTextSection TextSectionComponent
    | UpdateTextBody ( CKEditorID, CKEditorText )
      -- question msgs
    | UpdateQuestionField TextSectionComponent Question.Field.QuestionField
    | UpdateQuestionFieldValue TextSectionComponent Question.Field.QuestionField String
    | ToggleQuestionMenu TextSectionComponent Question.Field.QuestionField
    | DeleteQuestion TextSectionComponent Question.Field.QuestionField
    | SelectQuestion TextSectionComponent Question.Field.QuestionField Bool
    | DeleteSelectedQuestions TextSectionComponent
    | AddQuestion TextSectionComponent
      -- answer msgs
    | UpdateAnswerField TextSectionComponent Answer.Field.AnswerField
    | UpdateAnswerFieldValue TextSectionComponent Answer.Field.AnswerField String
    | UpdateAnswerFeedbackValue TextSectionComponent Answer.Field.AnswerField String
    | UpdateAnswerFieldCorrect TextSectionComponent Answer.Field.AnswerField Bool
    | AddAnswer TextSectionComponent Answer.Field.AnswerField
    | DeleteAnswer TextSectionComponent Answer.Field.AnswerField
      -- UI effects-related messages
    | ToggleEditable TextSectionComponent Field


update :
    Msg
    -> { a | text_component : TextComponent }
    -> ( { a | text_component : TextComponent }, Cmd msg )
update msg model =
    let
        text_section_group =
            Text.Component.text_section_components model.text_component

        updt =
            Text.Section.Component.Group.update_components text_section_group
                >> Text.Component.set_text_section_components model.text_component
    in
    case msg of
        -- text msgs
        AddTextSection ->
            let
                new_group =
                    Text.Section.Component.Group.add_new_text_section text_section_group
            in
            ( { model | text_component = Text.Component.set_text_section_components model.text_component new_group }
            , Cmd.none
            )

        DeleteTextSection text_section_component ->
            let
                text_section_body_id =
                    Text.Section.Component.body_id text_section_component

                new_group =
                    Text.Section.Component.Group.delete_text_section text_section_group text_section_component
            in
            ( { model | text_component = Text.Component.set_text_section_components model.text_component new_group }
            , Text.Section.Component.Group.reinitialize_ck_editors new_group
            )

        UpdateTextValue text_component field_name input ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.set_field_value text_component field_name input)
              }
            , Cmd.none
            )

        UpdateTextBody ( ckeditor_id, ckeditor_text ) ->
            case String.split "_" ckeditor_id of
                [ "textsection", i, "body" ] ->
                    case String.toInt i of
                        Just i_ ->
                            ( { model
                                | text_component =
                                    Text.Component.set_text_section_components model.text_component
                                        (Text.Section.Component.Group.update_body_for_section_index text_section_group i_ ckeditor_text)
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

                -- not a valid index
                _ ->
                    ( model, Cmd.none )

        -- not interested in this update
        -- question msgs
        AddQuestion text_component ->
            ( { model | text_component = updt (Text.Section.Component.add_new_question text_component) }, Cmd.none )

        UpdateQuestionField text_component question_field ->
            ( { model | text_component = updt (Text.Section.Component.update_question_field text_component question_field) }
            , Cmd.none
            )

        UpdateQuestionFieldValue text_component question_field value ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.update_question_field text_component
                            (Question.Field.set_question_body question_field value)
                        )
              }
            , Cmd.none
            )

        DeleteQuestion text_component question_field ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.delete_question_field text_component question_field)
              }
            , Cmd.none
            )

        SelectQuestion text_component question_field selected ->
            let
                new_question_field =
                    Question.Field.set_selected question_field selected
            in
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.update_question_field text_component new_question_field)
              }
            , Cmd.none
            )

        DeleteSelectedQuestions text_component ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.delete_selected_question_fields text_component)
              }
            , Cmd.none
            )

        ToggleQuestionMenu text_component question_field ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.toggle_question_menu text_component question_field)
              }
            , Cmd.none
            )

        -- answer msgs
        UpdateAnswerField text_component answer_field ->
            ( { model | text_component = updt (Text.Section.Component.set_answer text_component answer_field) }, Cmd.none )

        UpdateAnswerFieldValue text_component answer_field text ->
            ( { model | text_component = updt (Text.Section.Component.set_answer_text text_component answer_field text) }
            , Cmd.none
            )

        UpdateAnswerFeedbackValue text_component answer_field feedback ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.set_answer_feedback text_component answer_field feedback)
              }
            , Cmd.none
            )

        UpdateAnswerFieldCorrect text_component answer_field correct ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.set_answer_correct text_component answer_field)
              }
            , Cmd.none
            )

        AddAnswer text_section_component answer_field ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.add_answer text_section_component answer_field)
              }
            , Cmd.none
            )

        DeleteAnswer text_section_component answer_field ->
            ( { model
                | text_component =
                    updt
                        (Text.Section.Component.delete_answer text_section_component answer_field)
              }
            , Cmd.none
            )

        -- ui msgs
        ToggleEditable text_component field ->
            let
                extra_cmds =
                    case field of
                        Text text_field ->
                            Text.Section.Component.post_toggle_commands text_field

                        _ ->
                            [ Cmd.none ]

                new_text_component =
                    case field of
                        Text fld ->
                            Text.Section.Component.set_field text_component (Text.Section.Component.switch_editable fld)

                        Question fld ->
                            Text.Section.Component.set_question text_component (Question.Field.switch_editable fld)

                        Answer fld ->
                            Text.Section.Component.set_answer text_component (Answer.Field.switch_editable fld)
            in
            ( { model | text_component = updt new_text_component }, Cmd.batch <| extra_cmds ++ [ post_toggle_field field ] )


post_toggle_field : Field -> Cmd msg
post_toggle_field field =
    let
        ( field_editable, field_id ) =
            case field of
                Text fld ->
                    ( Text.Section.Component.editable fld, Text.Section.Component.text_field_id fld )

                Question fld ->
                    ( Question.Field.editable fld, Question.Field.id fld )

                Answer fld ->
                    ( Answer.Field.editable fld, Answer.Field.id fld )
    in
    if not field_editable then
        selectAllInputText field_id

    else
        Cmd.none
