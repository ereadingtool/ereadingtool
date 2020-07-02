module Admin.Text exposing (..)


type URL = URL String

type TextAPIEndpoint = TextAPIEndpoint URL


urlToString : URL -> String
urlToString (URL url) =
  url

textAPIEndpointURL : TextAPIEndpoint -> URL
textAPIEndpointURL (TextAPIEndpoint url) =
  url

textEndpointToString : TextAPIEndpoint -> String
textEndpointToString endpoint =
  urlToString (textAPIEndpointURL endpoint)

