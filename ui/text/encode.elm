module Text.Encode exposing (textEncoder)

import Json.Encode as Encode

import Text.Model
import Text.Section.Encode exposing (textSectionsEncoder)


textEncoder : Text.Model.Text -> Encode.Value
textEncoder text =
  Encode.object [
      ("introduction", Encode.string text.introduction)
      ("title", Encode.string text.title)
    , ("source", Encode.string text.source)
    , ("difficulty", Encode.string text.difficulty)
    , ("author", Encode.string text.author)
    , ("sections", textSectionsEncoder text.sections)
    , ("tags", Encode.list
        (case text.tags of
          Just tags -> List.map (\tag -> Encode.string tag) tags
          _ -> []))
  ]
