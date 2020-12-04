module Text.Section.Component.Group exposing
    ( TextSectionComponentGroup
    , add_new_text_section
    , delete_text_section
    , fromTextSections
    , new_group
    , reinitialize_ck_editors
    , text_section_component
    , toArray
    , toTextSections
    , update_body_for_section_index
    , update_components
    , update_errors
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Ports exposing (CKEditorText)
import Text.Section.Component exposing (TextSectionComponent)
import Text.Section.Model


type TextSectionComponentGroup
    = TextSectionComponentGroup (Array TextSectionComponent)


new_group : TextSectionComponentGroup
new_group =
    TextSectionComponentGroup (Array.fromList [ Text.Section.Component.emptyTextSectionComponent 0 ])


update_error : ( String, String ) -> Array TextSectionComponent -> Array TextSectionComponent
update_error ( field_id, field_error ) text_section_components =
    -- error keys begin with text_i_*
    let
        error_key =
            String.split "_" field_id
    in
    case error_key of
        "textsection" :: index :: _ ->
            case String.toInt index of
                Just i ->
                    case Array.get i text_section_components of
                        Just textSectionComponent ->
                            let
                                -- only pass the relevant part of the error key
                                text_component_error =
                                    String.join "_" (List.drop 2 error_key)

                                new_text_component_with_errors =
                                    Text.Section.Component.update_errors textSectionComponent ( text_component_error, field_error )
                            in
                            Array.set i new_text_component_with_errors text_section_components

                        Nothing ->
                            text_section_components

                -- section doesn't exist in the group
                Nothing ->
                    text_section_components

        -- not a valid index string
        _ ->
            text_section_components



-- not a valid error key


update_errors : TextSectionComponentGroup -> Dict String String -> TextSectionComponentGroup
update_errors ((TextSectionComponentGroup text_components) as text_component_group) errors =
    TextSectionComponentGroup
        (Array.foldr update_error (toArray text_component_group) (Array.fromList <| Dict.toList errors))


update_components : TextSectionComponentGroup -> TextSectionComponent -> TextSectionComponentGroup
update_components (TextSectionComponentGroup text_components) text_component =
    TextSectionComponentGroup (Array.set (Text.Section.Component.index text_component) text_component text_components)


add_new_text_section : TextSectionComponentGroup -> TextSectionComponentGroup
add_new_text_section (TextSectionComponentGroup text_components) =
    let
        arr_len =
            Array.length text_components

        new_component =
            Text.Section.Component.emptyTextSectionComponent arr_len

        new_sections =
            Array.push new_component text_components
    in
    TextSectionComponentGroup new_sections


delete_text_section : TextSectionComponentGroup -> TextSectionComponent -> TextSectionComponentGroup
delete_text_section (TextSectionComponentGroup text_components) textSectionComponent =
    let
        index =
            Text.Section.Component.index

        component_index =
            index textSectionComponent

        new_sections =
            Array.indexedMap (\i text_component -> Text.Section.Component.set_index text_component i) <|
                Array.filter (\text_component -> index text_component /= component_index) text_components
    in
    TextSectionComponentGroup new_sections


toArray : TextSectionComponentGroup -> Array TextSectionComponent
toArray (TextSectionComponentGroup text_components) =
    text_components


toTextSections : TextSectionComponentGroup -> Array Text.Section.Model.TextSection
toTextSections text_components =
    Array.map Text.Section.Component.toTextSection (toArray text_components)


fromTextSections : Array Text.Section.Model.TextSection -> TextSectionComponentGroup
fromTextSections text_sections =
    TextSectionComponentGroup (Array.indexedMap Text.Section.Component.fromTextSection text_sections)


text_section_component : TextSectionComponentGroup -> Int -> Maybe TextSectionComponent
text_section_component (TextSectionComponentGroup text_components) index =
    Array.get index text_components


reinitialize_ck_editors : TextSectionComponentGroup -> Cmd msg
reinitialize_ck_editors text_component_group =
    let
        text_components =
            toArray text_component_group
    in
    Cmd.batch <| Array.toList <| Array.map Text.Section.Component.reinitialize_ck_editor text_components


update_body_for_section_index : TextSectionComponentGroup -> Int -> CKEditorText -> TextSectionComponentGroup
update_body_for_section_index text_sections index ckeditor_text =
    case text_section_component text_sections index of
        Just text_component ->
            update_components text_sections (Text.Section.Component.update_body text_component ckeditor_text)

        _ ->
            text_sections



-- text section not found
