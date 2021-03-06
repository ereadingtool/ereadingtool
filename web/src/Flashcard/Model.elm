module Flashcard.Model exposing
    ( CmdReq(..)
    , CmdResp(..)
    , Exception
    , Flashcard
    , InitRespRec
    , Model
    , SessionState(..)
    , disconnect
    , example
    , hasException
    , inReview
    , newFlashcard
    , setException
    , setMode
    , setQuality
    , setSessionState
    , translationOrPhrase
    )

import Flashcard.Mode exposing (Mode)
import User.Profile


type alias Exception =
    { code : String, error_msg : String }


type alias Example =
    String


type alias Phrase =
    String


type alias WebSocketAddress =
    String


type alias TranslatedPhrase =
    String


type alias Rating =
    Int


type alias InitRespRec =
    { flashcards : List String
    }


type SessionState
    = Loading
    | Init InitRespRec
    | ViewModeChoices (List Flashcard.Mode.ModeChoiceDesc)
    | ReviewCard Flashcard
    | ReviewedCard Flashcard
    | ReviewCardAndAnswer Flashcard
    | ReviewedCardAndAnsweredCorrectly Flashcard
    | ReviewedCardAndAnsweredIncorrectly Flashcard
    | RatedCard Flashcard
    | FinishedReview


type Flashcard
    = Flashcard Phrase Example (Maybe TranslatedPhrase)


disconnect : Model -> Model
disconnect model =
    { model | connect = False }


setMode : Model -> Maybe Mode -> Model
setMode model mode =
    { model | mode = mode }


setQuality : Model -> Maybe Rating -> Model
setQuality model rating =
    { model | selected_quality = rating }


setSessionState : Model -> SessionState -> Model
setSessionState original_model session_state =
    let
        model =
            setException original_model Nothing
    in
    { model | session_state = session_state }


setException : Model -> Maybe Exception -> Model
setException model exception =
    { model | exception = exception }


inReview : Model -> Bool
inReview model =
    case model.session_state of
        FinishedReview ->
            False

        _ ->
            True


hasException : Model -> Bool
hasException model =
    case model.exception of
        Just _ ->
            True

        _ ->
            False


newFlashcard : Phrase -> Example -> Maybe TranslatedPhrase -> Flashcard
newFlashcard phr ex trans =
    Flashcard phr ex trans


example : Flashcard -> Example
example (Flashcard _ ex _) =
    "\"" ++ ex ++ "\""


phrase : Flashcard -> Phrase
phrase (Flashcard phr _ _) =
    phr


translation : Flashcard -> Maybe TranslatedPhrase
translation (Flashcard _ _ trans) =
    trans


translationOrPhrase : Flashcard -> String
translationOrPhrase flashcard =
    case translation flashcard of
        Just tr ->
            tr ++ " - " ++ phrase flashcard

        Nothing ->
            phrase flashcard


type alias Model =
    { profile : User.Profile.Profile

    -- , menu_items : Menu.Items.MenuItems
    , mode : Maybe Mode
    , session_state : SessionState
    , exception : Maybe Exception
    , connect : Bool
    , answer : String
    , selected_quality : Maybe Int

    -- , flags : Flags
    }


type CmdReq
    = ChooseModeReq Mode
    | StartReq
    | NextReq
    | PrevReq
    | ReviewAnswerReq
    | AnswerReq String
    | RateQualityReq Int


type CmdResp
    = InitResp InitRespRec
    | ChooseModeChoiceResp (List Flashcard.Mode.ModeChoiceDesc)
    | ReviewCardResp Flashcard
    | ReviewCardAndAnswerResp Flashcard
    | ReviewedCardAndAnsweredCorrectlyResp Flashcard
    | ReviewedCardAndAnsweredIncorrectlyResp Flashcard
    | RatedCardResp Flashcard
    | ReviewedCardResp Flashcard
    | ExceptionResp Exception
    | FinishedReviewResp
