module Text.Translations.Word.Kind exposing (WordKind(..))

import Text.Translations exposing (TextGroupDetails)


type WordKind
    = SingleWord (Maybe TextGroupDetails)
    | CompoundWord
