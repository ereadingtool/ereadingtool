module Text.Subscriptions exposing (subscriptions)

import Ports exposing (ckEditorUpdate)
import Text.Update exposing (Msg)


subscriptions : (Msg -> msg) -> { a | text_component : TextComponent } -> Sub msg
subscriptions msg model =
    ckEditorUpdate (Text.Update.UpdateTextBody >> msg)
