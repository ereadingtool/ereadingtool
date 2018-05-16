module Text.Subscriptions exposing (..)

{-import Ports exposing (selectAllInputText, ckEditor, ckEditorUpdate)-}
import Text.Update exposing (Msg)
import Text.Component.Group

subscriptions : (Msg -> msg) -> { a | text_components: Text.Component.Group.TextComponentGroup} -> Sub msg
subscriptions msg model = Sub.none
  {- ckEditorUpdate Text.Update.UpdateTextBody -}
