module Text.Translations.Word.Instance exposing
    ( WordInstance
    , canMergeWords
    , grammemeKeys
    , grammemeValue
    , grammemes
    , hasTextWord
    , id
    , instance
    , new
    , sectionNumber
    , setTextWord
    , textWord
    , token
    , word
    , wordInstanceSectionNumberToInt
    )

import Set exposing (Set)
import Text.Translations exposing (..)
import Text.Translations.TextWord exposing (TextWord)


type WordInstance
    = WordInstance SectionNumber Instance Token (Maybe TextWord)


setTextWord : WordInstance -> TextWord -> WordInstance
setTextWord (WordInstance id instance token _) newTextWord =
    WordInstance id instance token (Just newTextWord)


canMergeWords : List WordInstance -> Bool
canMergeWords wordInstances =
    List.all hasTextWord wordInstances


hasTextWord : WordInstance -> Bool
hasTextWord (WordInstance _ _ _ textWord) =
    case textWord of
        Just _ ->
            True

        Nothing ->
            False


grammemeValue : WordInstance -> String -> Maybe String
grammemeValue wordInstance grammemeName =
    textWord wordInstance
        |> Maybe.andThen (\tw -> Text.Translations.TextWord.grammemeValue tw grammemeName)


grammemeKeys : Set String
grammemeKeys =
    Text.Translations.expectedGrammemeKeys


grammemes : WordInstance -> Maybe Grammemes
grammemes wordInstance =
    textWord wordInstance
        |> Maybe.andThen Text.Translations.TextWord.grammemes


sectionNumber : WordInstance -> SectionNumber
sectionNumber (WordInstance sectionNumber _ _ _) =
    sectionNumber


wordInstanceSectionNumberToInt : WordInstance -> Int
wordInstanceSectionNumberToInt wordInstance =
    sectionNumberToInt (sectionNumber wordInstance)


id : WordInstance -> Id
id (WordInstance sectionNumber instance token _) =
    String.join "_" [ toString sectionNumber, toString instance, String.join "_" (String.words (String.toLower token)) ]


token : WordInstance -> Token
token (WordInstance _ _ token _) =
    token


textWord : WordInstance -> Maybe TextWord
textWord (WordInstance _ _ _ textWord) =
    textWord


instance : WordInstance -> Instance
instance (WordInstance _ instance _ _) =
    instance


word : WordInstance -> Token
word (WordInstance _ _ word _) =
    word


normalizeToken : String -> String
normalizeToken =
    String.toLower


new : SectionNumber -> Instance -> Token -> Maybe TextWord -> WordInstance
new sectionNumber instance token textWord =
    WordInstance sectionNumber instance token textWord
