module Text.Translations.Msg exposing (Msg, Msg(..))

import Array exposing (Array)

import Http
import Dict exposing (Dict)

import Text.Translations exposing (..)

import Text.Translations.TextWord exposing (TextWord)

import Text.Translations.Decode

import Text.Translations.Word.Instance exposing (WordInstance)


type Msg =
  -- action msgs
  -- merges
    AddToMergeWords WordInstance
  | RemoveFromMergeWords WordInstance
  | MergeWords (List WordInstance)
  | AddedTextWordsForMerge (List TextWord)
  | MergeFail Http.Error

  -- words
  | AddTextWord WordInstance
  | EditWord WordInstance
  | CloseEditWord WordInstance
  | DeleteTextWord TextWord

  -- translations
  | MakeCorrectForContext Translation
  | UpdateNewTranslationForTextWord TextWord String
  | SubmitNewTranslationForTextWord TextWord
  | DeleteTranslation TextWord Translation
  | MatchTranslations WordInstance

  -- grammemes
  | SelectGrammemeForEditing WordInstance String
  | InputGrammeme WordInstance String
  | SaveEditedGrammemes WordInstance
  | RemoveGrammeme WordInstance String

  -- result msgs
  -- words
  | MergedWords (Result Http.Error Text.Translations.Decode.TextWordMergeResp)
  | DeletedTextWord (Result Http.Error TextWord)
  | UpdatedTextWord (Result Http.Error TextWord)
  | UpdatedTextWords (Result Http.Error (List TextWord))

  -- translations
  | UpdateTextTranslations (Result Http.Error (Array (Dict Text.Translations.Word (Array TextWord))))
  | UpdateTextTranslation (Result Http.Error (TextWord, Translation))
  | SubmittedTextTranslation (Result Http.Error (TextWord, Translation))
  | DeletedTranslation (Result Http.Error Text.Translations.Decode.TextWordTranslationDeleteResp)
