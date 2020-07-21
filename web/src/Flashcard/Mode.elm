module Flashcard.Mode exposing (..)


type alias ModeId =
    String


type Mode
    = ReviewOnly ModeId
    | ReviewAndAnswer ModeId


modeName : Mode -> String
modeName mode_choice =
    case mode_choice of
        ReviewOnly _ ->
            "Review Only"

        ReviewAndAnswer _ ->
            "Review and Answer"


modeId : Mode -> ModeId
modeId mode_choice =
    case mode_choice of
        ReviewOnly id ->
            id

        ReviewAndAnswer id ->
            id


modeFromString : String -> Mode
modeFromString str =
    case str of
        "review" as id ->
            ReviewOnly id

        "review_and_answer" as id ->
            ReviewAndAnswer id

        _ ->
            ReviewOnly "review"


type alias ModeChoiceDesc =
    { mode : Mode, desc : String, selected : Bool }
