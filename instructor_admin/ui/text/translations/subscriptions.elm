module Text.Translations.Subscriptions exposing (..)

import Ports

import Text.Translations.Msg exposing (Msg, Msg(..))
import Text.Translations.Model exposing (Model)


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions msg model =
  Sub.batch [
    Ports.selectedText (SelectedText >> msg)
  ]
