module Text.Update exposing (update, Msg(..))

import Array exposing (Array)
import Text.Field

type Msg =
    UpdateID String String


update : Msg
  -> {a | text_components: Array Text.Field.TextComponent}
  -> ( {a | text_components: Array Text.Field.TextComponent}, Cmd msg )
update msg model = case msg of
  UpdateID id value -> ({ model | text_components = Text.Field.add_new_text (Array.fromList [])}, Cmd.none)

