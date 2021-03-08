module TextReader.Flashcard.Student exposing (..)

import Dict exposing (Dict)
import Student.Profile exposing (StudentProfile)
import Text.Translations.Decode exposing (Flashcards, TextWord)
import TextReader.TextWord


type StudentFlashcards
    = StudentFlashcards StudentProfile Text.Translations.Decode.Flashcards


newStudentFlashcards : StudentProfile -> Maybe Text.Translations.Decode.Flashcards -> StudentFlashcards
newStudentFlashcards student_profile cards =
    StudentFlashcards student_profile (Maybe.withDefault Dict.empty cards)


flashcards : StudentFlashcards -> Flashcards
flashcards (StudentFlashcards _ cards) =
    cards


addFlashcard : StudentFlashcards -> TextReader.TextWord.TextWord -> StudentFlashcards
addFlashcard (StudentFlashcards profile cards) text_word =
    let
        phrase =
            TextReader.TextWord.phrase text_word
    in
    StudentFlashcards profile (Dict.insert phrase text_word cards)


removeFlashcard : StudentFlashcards -> TextReader.TextWord.TextWord -> StudentFlashcards
removeFlashcard (StudentFlashcards profile cards) text_word =
    let
        phrase =
            TextReader.TextWord.phrase text_word

        new_flashcards =
            Dict.remove phrase cards
    in
    StudentFlashcards profile new_flashcards
