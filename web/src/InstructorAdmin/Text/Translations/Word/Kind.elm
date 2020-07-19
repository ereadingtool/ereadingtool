module InstructorAdmin.Text.Translations.Word.Kind exposing (WordKind(..))

import InstructorAdmin.Text.Translations exposing (TextGroupDetails)


type WordKind
    = SingleWord (Maybe TextGroupDetails)
    | CompoundWord
