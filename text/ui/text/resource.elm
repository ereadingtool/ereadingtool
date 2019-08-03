module Text.Resource exposing (..)

import Json.Decode

type URL = URL String
type TextReadingURL = TextReadingURL URL

urlToString : URL -> String
urlToString (URL url) =
  url

textReadingURL : TextReadingURL -> URL
textReadingURL (TextReadingURL url) =
  url

textReadingURLToString : TextReadingURL -> String
textReadingURLToString text_reading_url =
  urlToString (textReadingURL text_reading_url)

urlDecoder : Json.Decode.Decoder URL
urlDecoder =
  Json.Decode.map URL (Json.Decode.string)

textURLDecoder : Json.Decode.Decoder TextReadingURL
textURLDecoder =
  Json.Decode.map TextReadingURL urlDecoder