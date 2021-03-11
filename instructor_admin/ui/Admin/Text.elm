module Admin.Text exposing (TextAPIEndpoint, toTextAPIEndpoint, URL, textAPIEndpointURL, textEndpointToString)


type URL
    = URL String


type TextAPIEndpoint
    = TextAPIEndpoint URL


toURL : String -> URL
toURL urlString =
    URL urlString


toTextAPIEndpoint : String -> TextAPIEndpoint
toTextAPIEndpoint urlString =
    TextAPIEndpoint (toURL urlString)


urlToString : URL -> String
urlToString (URL url) =
    url


textAPIEndpointURL : TextAPIEndpoint -> URL
textAPIEndpointURL (TextAPIEndpoint url) =
    url


textEndpointToString : TextAPIEndpoint -> String
textEndpointToString endpoint =
    urlToString (textAPIEndpointURL endpoint)
