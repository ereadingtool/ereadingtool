module Help.Activities exposing (..)

import Dict exposing (Dict)


type alias Answer =
    { answer : String
    , correct : Bool
    , selected : Bool
    }


type Activity
    = Activity (Dict String Question)


type Question
    = Question (Dict String Answer) { showButton : Bool, showSolution : Bool }


questions : Activity -> Dict String Question
questions (Activity qs) =
    qs


answers : Question -> Dict String Answer
answers (Question ans _) =
    ans


showButton : Question -> Bool
showButton (Question _ visibilityRecord) =
    visibilityRecord.showButton


showSolution : Question -> Bool
showSolution (Question _ visibilityRecord) =
    visibilityRecord.showSolution
