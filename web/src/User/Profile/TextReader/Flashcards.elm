module User.Profile.TextReader.Flashcards exposing (..)

import InstructorAdmin.Text.Translations.Decode exposing (Flashcards)
import TextReader.Flashcard.Student
import TextReader.TextWord
import User.Profile exposing (Profile)
import User.Student.Profile exposing (StudentProfile)


type ProfileFlashcards
    = StudentFlashcards TextReader.Flashcard.Student.StudentFlashcards
    | InstructorFlashcards


initFlashcards : Profile -> Flashcards -> ProfileFlashcards
initFlashcards profile cards =
    case profile of
        User.Profile.Student student_profile ->
            fromStudentFlashcards student_profile cards

        _ ->
            InstructorFlashcards


fromStudentFlashcards : StudentProfile -> Flashcards -> ProfileFlashcards
fromStudentFlashcards student_profile cards =
    let
        student_flashcards =
            TextReader.Flashcard.Student.newStudentFlashcards student_profile (Just cards)
    in
    StudentFlashcards student_flashcards


flashcards : ProfileFlashcards -> Maybe Flashcards
flashcards profile_flashcards =
    case profile_flashcards of
        StudentFlashcards student_flashcards ->
            Just (TextReader.Flashcard.Student.flashcards student_flashcards)

        _ ->
            Nothing


addFlashcard : ProfileFlashcards -> TextReader.TextWord.TextWord -> ProfileFlashcards
addFlashcard profile_flashcards text_word =
    case profile_flashcards of
        StudentFlashcards student_flashcards ->
            StudentFlashcards (TextReader.Flashcard.Student.addFlashcard student_flashcards text_word)

        _ ->
            profile_flashcards


removeFlashcard : ProfileFlashcards -> TextReader.TextWord.TextWord -> ProfileFlashcards
removeFlashcard profile_flashcards text_word =
    case profile_flashcards of
        StudentFlashcards student_flashcards ->
            StudentFlashcards (TextReader.Flashcard.Student.removeFlashcard student_flashcards text_word)

        _ ->
            profile_flashcards
