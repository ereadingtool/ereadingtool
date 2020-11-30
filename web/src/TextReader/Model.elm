module TextReader.Model exposing
    ( CmdReq(..)
    , CmdResp(..)
    , Exception
    , Gloss
    , Model
    , Progress(..)
    , TextReaderWord
    , TextScores
    , gloss
    , glossed
    , instance
    , new
    , phrase
    , selected
    , toggleGloss
    , ungloss
    )

import Dict exposing (Dict)
import InstructorAdmin.Text.Translations exposing (Id, Instance, Phrase)
import Text.Resource
import TextReader.Answer.Model exposing (Answer, AnswerCorrect, TextAnswer)
import TextReader.Section.Model exposing (Section)
import TextReader.Text.Model exposing (Text)
import TextReader.TextWord
import User.Profile
import User.Profile.TextReader.Flashcards


type Progress
    = Init
    | ViewIntro
    | ViewSection Section
    | Complete TextScores


type alias Exception =
    { code : String, error_msg : String }


type alias Gloss =
    Dict String Bool


type alias Flashcards =
    Dict String Bool


type TextReaderWord
    = TextReaderWord Id Instance Phrase (Maybe TextReader.TextWord.TextWord)


new : Id -> Instance -> Phrase -> Maybe TextReader.TextWord.TextWord -> TextReaderWord
new id inst phr text_word =
    TextReaderWord id inst phr text_word


identifier : TextReaderWord -> Id
identifier (TextReaderWord id _ _ _) =
    id


textWord : TextReaderWord -> Maybe TextReader.TextWord.TextWord
textWord (TextReaderWord _ _ _ text_word) =
    text_word


instance : TextReaderWord -> Instance
instance (TextReaderWord _ inst _ _) =
    inst


phrase : TextReaderWord -> Phrase
phrase (TextReaderWord _ _ phr _) =
    phr


gloss : TextReaderWord -> Gloss -> Gloss
gloss reader_word glosses =
    Dict.insert (identifier reader_word) True (Dict.insert (String.toLower (phrase reader_word)) True glosses)


ungloss : TextReaderWord -> Gloss -> Gloss
ungloss reader_word glosses =
    Dict.remove (identifier reader_word) (Dict.remove (String.toLower (phrase reader_word)) glosses)


toggleGloss : TextReaderWord -> Gloss -> Gloss
toggleGloss reader_word glosses =
    if selected reader_word glosses then
        ungloss reader_word glosses

    else
        gloss reader_word glosses



-- this is for any instance of a word


glossed : TextReaderWord -> Gloss -> Bool
glossed reader_word gls =
    Dict.member (String.toLower (phrase reader_word)) gls



-- this is for a particular instance of a word (using `identifer`)


selected : TextReaderWord -> Gloss -> Bool
selected reader_word gls =
    Dict.member (identifier reader_word) gls


type CmdReq
    = NextReq
    | PrevReq
    | AnswerReq TextAnswer
    | AddToFlashcardsReq TextReaderWord
    | RemoveFromFlashcardsReq TextReaderWord


type CmdResp
    = StartResp Text
    | InProgressResp Section
    | CompleteResp TextScores
    | AddToFlashcardsResp TextReader.TextWord.TextWord
    | RemoveFromFlashcardsResp TextReader.TextWord.TextWord
    | ExceptionResp Exception


type alias TextScores =
    { num_of_sections : Int
    , complete_sections : Int
    , section_scores : Int
    , possible_section_scores : Int
    }


type alias Model =
    { text : Text
    , text_url : Text.Resource.TextReadingURL
    , profile : User.Profile.Profile
    , flashcard : User.Profile.TextReader.Flashcards.ProfileFlashcards
    , progress : Progress
    , gloss : Gloss
    , exception : Maybe Exception
    }
