module Text.Subscriptions exposing (subscriptions)

import Ports exposing (ckEditor, ckEditorUpdate, selectAllInputText)
import Text.Component as Text exposing (TextComponent)
import Text.Update exposing (Msg)


subscriptions : (Msg -> msg) -> { a | text_component : TextComponent } -> Sub msg
subscriptions msg model =
    ckEditorUpdate (Text.Update.UpdateTextBody >> msg)
