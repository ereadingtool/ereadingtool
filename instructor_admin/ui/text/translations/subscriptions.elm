module Text.Translations.Subscriptions exposing (..)

import Text.Translations.Msg exposing (Msg)
import Text.Translations.Model exposing (Model)


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions parent_msg model =
  Sub.batch [
  ]
