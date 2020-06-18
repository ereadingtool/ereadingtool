module TextReader.Flashcard.Student exposing (..)

import Dict exposing (Dict)
import Student.Profile exposing (StudentProfile)
import Text.Translations.Decode exposing (Flashcards, TextWord)
import TextReader.TextWord


type StudentFlashcards
    = StudentFlashcards StudentProfile Text.Translations.Decode.Flashcards


newStudentFlashcards : StudentProfile -> Maybe Text.Translations.Decode.Flashcards -> StudentFlashcards
newStudentFlashcards student_profile flashcards =
    StudentFlashcards student_profile (Maybe.withDefault Dict.empty flashcards)


flashcards : StudentFlashcards -> Flashcards
flashcards (StudentFlashcards profile flashcards) =
    flashcards


addFlashcard : StudentFlashcards -> TextReader.TextWord.TextWord -> StudentFlashcards
addFlashcard (StudentFlashcards profile flashcards) text_word =
    let
        phrase =
            TextReader.TextWord.phrase text_word
    in
    StudentFlashcards profile (Dict.insert phrase text_word flashcards)


removeFlashcard : StudentFlashcards -> TextReader.TextWord.TextWord -> StudentFlashcards
removeFlashcard (StudentFlashcards profile flashcards) text_word =
    let
        phrase =
            TextReader.TextWord.phrase text_word

        new_flashcards =
            Dict.remove phrase flashcards
    in
    StudentFlashcards profile new_flashcards
