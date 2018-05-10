module Field exposing (..)

import Json.Decode as Decode
import Array exposing (Array)

type alias ID = Int
type alias Editable = Bool
type alias Hover = Bool
type alias Index = Int
type alias Error = Bool

fieldIDDecoder : Decode.Decoder (ID)
fieldIDDecoder = Decode.int

type alias FieldAttributes a = { a | id: String, editable: Bool, hover: Bool, error: Bool, index: Int }


toggle_editable : { a | hover : Bool, index : Int, editable : Bool, error: Bool }
    -> Array { a | index : Int, editable : Bool, hover : Bool, error: Bool }
    -> Array { a | index : Int, editable : Bool, hover : Bool, error: Bool }
toggle_editable field fields =
  Array.set field.index { field |
      editable = (if field.editable then False else True)
    , hover=False
    , error=False }
  fields

set_hover
    : { a | hover : Bool, index : Int }
    -> Bool
    -> Array { a | index : Int, hover : Bool }
    -> Array { a | index : Int, hover : Bool }
set_hover field hover fields = Array.set field.index { field | hover = hover } fields
