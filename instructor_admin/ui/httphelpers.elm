module HttpHelpers exposing (post_with_headers)

import Http
import Json.Decode as Decode

post_with_headers : String -> List Http.Header -> Http.Body -> Decode.Decoder a -> Http.Request a
post_with_headers url headers body decoder =
  Http.request
    { method = "POST"
    , headers = headers
    , url = url
    , body = body
    , expect = Http.expectJson decoder
    , timeout = Nothing
    , withCredentials = False
    }
