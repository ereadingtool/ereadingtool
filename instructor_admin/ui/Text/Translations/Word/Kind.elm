module Text.Translations.Word.Kind exposing (WordKind(..))

import Text.Translations exposing (..)


type WordKind = SingleWord (Maybe TextGroupDetails) | CompoundWord
