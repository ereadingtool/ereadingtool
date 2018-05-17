module Text.Subscriptions exposing (..)

import Ports exposing (selectAllInputText, ckEditor, ckEditorUpdate)
import Text.Update exposing (Msg)
import Text.Component.Group

subscriptions : (Msg -> msg) -> { a | text_components: Text.Component.Group.TextComponentGroup} -> Sub msg
subscriptions msg model = ckEditorUpdate (Text.Update.UpdateTextBody >> msg)
