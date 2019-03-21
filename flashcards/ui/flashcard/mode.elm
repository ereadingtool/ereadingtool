module Flashcard.Mode exposing (..)

type alias ModeId = String

type ModeChoice = ReviewOnly ModeId | ReviewAndAnswer ModeId

modeName : ModeChoice -> String
modeName mode_choice =
  case mode_choice of
    ReviewOnly _ ->
      "Review Only"

    ReviewAndAnswer _ ->
      "Review and Answer"


modeId : ModeChoice -> ModeId
modeId mode_choice =
  case mode_choice of
    ReviewOnly id ->
      id

    ReviewAndAnswer id ->
      id

modeFromString : String -> ModeChoice
modeFromString str =
  case str of
    "review" as id ->
      ReviewOnly id

    "review_and_answer" as id ->
      ReviewAndAnswer id

    _ ->
      ReviewOnly "review"


type alias ModeChoiceDesc = { mode: ModeChoice, desc: String, selected: Bool }
