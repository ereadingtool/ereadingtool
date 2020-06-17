module User.Profile.TextReader.Flashcards exposing (..)

import User.Profile exposing (Profile)

import Student.Profile

import Text.Translations.Decode exposing (Flashcards)
import TextReader.Flashcard.Student

import TextReader.TextWord

import TextReader.Flashcard.Student

type ProfileFlashcards =
    StudentFlashcards TextReader.Flashcard.Student.StudentFlashcards
  | InstructorFlashcards


initFlashcards : Profile -> Text.Translations.Decode.Flashcards -> ProfileFlashcards
initFlashcards profile flashcards =
  case profile of
    User.Profile.Student student_profile ->
      fromStudentFlashcards student_profile flashcards

    _ ->
      InstructorFlashcards

fromStudentFlashcards : Student.Profile.StudentProfile -> Text.Translations.Decode.Flashcards -> ProfileFlashcards
fromStudentFlashcards student_profile flashcards =
  let
    student_flashcards = TextReader.Flashcard.Student.newStudentFlashcards student_profile (Just flashcards)
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
