module Field exposing (..)

import Json.Decode as Decode
import Array exposing (Array)

type alias ID = Int
type alias Editable = Bool
type alias Index = Int
type alias Error = Bool

fieldIDDecoder : Decode.Decoder (ID)
fieldIDDecoder = Decode.int

type alias FieldAttributes a = { a | id: String, editable: Bool, error: Bool, index: Int }


toggle_editable : { a | index : Int, editable : Bool, error: Bool }
    -> Array { a | index : Int, editable : Bool, error: Bool }
    -> Array { a | index : Int, editable : Bool, error: Bool }
toggle_editable field fields =
  Array.set field.index { field |
      editable = (if field.editable then False else True)
    , error=False }
  fields
