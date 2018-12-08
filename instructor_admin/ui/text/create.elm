module Text.Create exposing (Flags, Mode(..), Msg(..), TextField(..), Model, TextViewParams, Tab(..))

import Time
import Dict exposing (Dict)

import Json.Encode

import Http

import Text.Model exposing (Text, TextDifficulty, TextWord, TextWords)

import Text.Translations.Model as TextTranslations
import Text.Translations.Msg

import Text.Update

import Instructor.Profile
import Flags

import Text.Model

import Text.Component exposing (TextComponent)
import Text.Field exposing (TextIntro, TextTitle, TextTags, TextAuthor, TextSource, TextDifficulty)
import Text.Decode

import Instructor.Profile
import Menu.Msg as MenuMsg
import Menu.Logout

type alias Flags = {
    instructor_profile : Instructor.Profile.InstructorProfileParams
  , csrftoken: Flags.CSRFToken
  , text: Maybe Json.Encode.Value
  , tags: List String }

type alias InstructorUser = String
type alias Tags = Dict String String
type alias Filter = List String
type alias WriteLocked = Bool

type Mode = EditMode | CreateMode | ReadOnlyMode InstructorUser

type Tab = TextTab | TranslationsTab

type TextField =
    Title TextTitle
  | Intro TextIntro
  | Tags TextTags
  | Author TextAuthor
  | Source TextSource
  | Difficulty Text.Field.TextDifficulty
  | Conclusion Text.Field.TextConclusion

type Msg =
    UpdateTextDifficultyOptions (Result Http.Error (List Text.Model.TextDifficulty))
  | TextTranslationMsg Text.Translations.Msg.Msg
  | SubmitText
  | Submitted (Result Http.Error Text.Decode.TextCreateResp)
  | Updated (Result Http.Error Text.Decode.TextUpdateResp)
  | TextComponentMsg Text.Update.Msg
  | ToggleEditable TextField Bool
  | UpdateTextAttributes String String
  | UpdateTextCkEditors (String, String)
  | TextJSONDecode (Result String TextComponent)
  | TextTagsDecode (Result String (Dict String String))
  | ClearMessages Time.Time
  | AddTagInput String String
  | DeleteTag String
  | ToggleLock
  | TextLocked (Result Http.Error Text.Decode.TextLockResp)
  | TextUnlocked (Result Http.Error Text.Decode.TextLockResp)
  | DeleteText
  | ConfirmTextDelete Bool
  | TextDelete (Result Http.Error Text.Decode.TextDeleteResp)
  | InitTextFieldEditors
  | ToggleTab Tab
  | LogOut MenuMsg.Msg
  | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Model = {
    flags : Flags
  , mode : Mode
  , profile : Instructor.Profile.InstructorProfile
  , success_msg : Maybe String
  , error_msg : Maybe String
  , text_component : TextComponent
  , text_difficulties : List Text.Model.TextDifficulty
  , text_translations_model: Maybe TextTranslations.Model
  , tags: Dict String String
  , write_locked: Bool
  , selected_tab: Tab }

type alias TextViewParams = {
    text: Text.Model.Text
  , text_component: TextComponent
  , text_fields: Text.Field.TextFields
  , profile: Instructor.Profile.InstructorProfile
  , tags: Dict String String
  , selected_tab: Tab
  , write_locked: WriteLocked
  , mode: Mode
  , text_difficulties: List Text.Model.TextDifficulty
  , text_translations_model: Maybe TextTranslations.Model
  , text_translation_msg: (Text.Translations.Msg.Msg -> Msg) }

