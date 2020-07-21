module InstructorAdmin.Text.Translations.Word.Instance exposing
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

import InstructorAdmin.Text.Translations as Translations exposing (Grammemes, Id, Instance, SectionNumber, Token)
import InstructorAdmin.Text.Translations.TextWord as TranslationsTextWord exposing (TextWord)
import Set exposing (Set)


type WordInstance
    = WordInstance SectionNumber Instance Token (Maybe TextWord)


setTextWord : WordInstance -> TextWord -> WordInstance
setTextWord (WordInstance sectNum inst tok _) newTextWord =
    WordInstance sectNum inst tok (Just newTextWord)


canMergeWords : List WordInstance -> Bool
canMergeWords wordInstances =
    List.all hasTextWord wordInstances


hasTextWord : WordInstance -> Bool
hasTextWord (WordInstance _ _ _ maybeTextWord) =
    case maybeTextWord of
        Just _ ->
            True

        Nothing ->
            False


grammemeValue : WordInstance -> String -> Maybe String
grammemeValue wordInstance grammemeName =
    textWord wordInstance
        |> Maybe.andThen (\tw -> TranslationsTextWord.grammemeValue tw grammemeName)


grammemeKeys : Set String
grammemeKeys =
    Translations.expectedGrammemeKeys


grammemes : WordInstance -> Maybe Grammemes
grammemes wordInstance =
    textWord wordInstance
        |> Maybe.andThen TranslationsTextWord.grammemes


sectionNumber : WordInstance -> SectionNumber
sectionNumber (WordInstance sectNum _ _ _) =
    sectNum


wordInstanceSectionNumberToInt : WordInstance -> Int
wordInstanceSectionNumberToInt wordInstance =
    Translations.sectionNumberToInt (sectionNumber wordInstance)


id : WordInstance -> Id
id (WordInstance sectNum inst tok _) =
    String.join "_" [ String.fromInt (Translations.sectionNumberToInt sectNum), String.fromInt inst, String.join "_" (String.words (String.toLower tok)) ]


token : WordInstance -> Token
token (WordInstance _ _ tok _) =
    tok


textWord : WordInstance -> Maybe TextWord
textWord (WordInstance _ _ _ maybeTextWord) =
    maybeTextWord


instance : WordInstance -> Instance
instance (WordInstance _ inst _ _) =
    inst


word : WordInstance -> Token
word (WordInstance _ _ tok _) =
    tok


normalizeToken : String -> String
normalizeToken =
    String.toLower


new : SectionNumber -> Instance -> Token -> Maybe TextWord -> WordInstance
new sectNum inst tok maybeTextWord =
    WordInstance sectNum inst tok maybeTextWord
