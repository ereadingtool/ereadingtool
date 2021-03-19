module Text.Translations.Subscriptions exposing (..)

import Text.Translations.Msg exposing (Msg, Msg(..))
import Text.Translations.Model exposing (Model)


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions msg model =
  Sub.none
