module Text.Subscriptions exposing (..)

import Ports exposing (selectAllInputText, ckEditor, ckEditorUpdate)
import Text.Update exposing (Msg)
import Text.Component as Text exposing (TextComponent)

subscriptions : (Msg -> msg) -> { a | text_component: TextComponent} -> Sub msg
subscriptions msg model =
  ckEditorUpdate (Text.Update.UpdateTextBody >> msg)
