module TextEdit exposing (Mode(..), Tab(..), TextViewParams)

import Dict exposing (Dict)
import Text.Component exposing (TextComponent)
import Text.Field
    exposing
        ( TextField(..)
        )
import Text.Model
import Text.Translations.Model as TranslationsModel
import User.Instructor.Profile exposing (InstructorProfile)


{-| Params passed to a editable text from the create or edit text page
-}
type alias TextViewParams =
    { text : Text.Model.Text
    , text_component : TextComponent
    , text_fields : Text.Field.TextFields
    , profile : InstructorProfile
    , tags : Dict String String
    , selected_tab : Tab
    , write_locked : WriteLocked
    , mode : Mode
    , text_difficulties : List Text.Model.TextDifficulty
    , text_translations_model : Maybe TranslationsModel.Model
    , translationServiceProcessed : Bool
    }


type alias WriteLocked =
    Bool


{-| Editing mode
-}
type Mode
    = EditMode
    | CreateMode
    | ReadOnlyMode InstructorUser


type alias InstructorUser =
    String


{-| Tab selected in create or edit text page
-}
type Tab
    = TextTab
    | TranslationsTab
