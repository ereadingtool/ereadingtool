module Text.Subscriptions exposing (..)

import Ports exposing (selectAllInputText, ckEditor, ckEditorUpdate)
import Text.Update exposing (Msg)
import Quiz.Component as Quiz exposing (QuizComponent)

subscriptions : (Msg -> msg) -> { a | quiz_component: QuizComponent} -> Sub msg
subscriptions msg model = ckEditorUpdate (Text.Update.UpdateTextBody >> msg)
