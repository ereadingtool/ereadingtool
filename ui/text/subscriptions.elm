module Text.Subscriptions exposing (..)

import Ports exposing (selectAllInputText, ckEditor, ckEditorUpdate)
import Text.Update exposing (Msg)
import Quiz.Model as Quiz exposing (Quiz)

subscriptions : (Msg -> msg) -> { a | quiz: Quiz} -> Sub msg
subscriptions msg model = ckEditorUpdate (Text.Update.UpdateTextBody >> msg)
