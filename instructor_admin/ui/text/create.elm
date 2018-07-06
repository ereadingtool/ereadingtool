module Quiz.Create exposing (Flags, Mode(..), Msg(..), QuizField(..), Model, QuizViewParams)

import Time
import Dict exposing (Dict)

import Json.Encode

import Http

import Text.Model exposing (Text, TextDifficulty)
import Text.Update

import Instructor.Profile
import Flags

import Quiz.Model
import Quiz.Component exposing (QuizComponent)
import Quiz.Field exposing (QuizIntro, QuizTitle, QuizTags)
import Quiz.Decode

import Instructor.Profile


type alias Flags = {
    instructor_profile : Instructor.Profile.InstructorProfileParams
  , csrftoken: Flags.CSRFToken
  , quiz: Maybe Json.Encode.Value
  , tags: List String }

type alias InstructorUser = String
type alias Tags = Dict String String
type alias Filter = List String
type alias WriteLocked = Bool

type Mode = EditMode | CreateMode | ReadOnlyMode InstructorUser

type QuizField = Title QuizTitle | Intro QuizIntro | Tags QuizTags

type Msg =
    UpdateTextDifficultyOptions (Result Http.Error (List TextDifficulty))
  | SubmitQuiz
  | Submitted (Result Http.Error Quiz.Decode.QuizCreateResp)
  | Updated (Result Http.Error Quiz.Decode.QuizUpdateResp)
  | TextComponentMsg Text.Update.Msg
  | ToggleEditable QuizField Bool
  | UpdateQuizAttributes String String
  | UpdateQuizIntro (String, String)
  | QuizJSONDecode (Result String QuizComponent)
  | QuizTagsDecode (Result String (Dict String String))
  | ClearMessages Time.Time
  | AddTagInput String String
  | DeleteTag String
  | ToggleLock
  | QuizLocked (Result Http.Error Quiz.Decode.QuizLockResp)
  | QuizUnlocked (Result Http.Error Quiz.Decode.QuizLockResp)
  | DeleteQuiz
  | ConfirmQuizDelete Bool
  | QuizDelete (Result Http.Error Quiz.Decode.QuizDeleteResp)

type alias Model = {
    flags : Flags
  , mode : Mode
  , profile : Instructor.Profile.InstructorProfile
  , success_msg : Maybe String
  , error_msg : Maybe String
  , quiz_component : QuizComponent
  , text_difficulties : List TextDifficulty
  , tags: Dict String String
  , write_locked: Bool }

type alias QuizViewParams = {
    quiz: Quiz.Model.Quiz
  , quiz_component: QuizComponent
  , quiz_fields: Quiz.Field.QuizFields
  , profile: Instructor.Profile.InstructorProfile
  , tags: Dict String String
  , write_locked: WriteLocked
  , mode: Mode
  , text_difficulties: List TextDifficulty }

