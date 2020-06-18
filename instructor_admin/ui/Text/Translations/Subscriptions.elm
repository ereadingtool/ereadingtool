module Text.Translations.Subscriptions exposing (..)

import Text.Translations.Model exposing (Model)
import Text.Translations.Msg exposing (Msg(..))


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions msg model =
    Sub.none
