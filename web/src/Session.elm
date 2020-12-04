module Session exposing (Session, changes, cred, fromViewer, viewer)

import Api exposing (Cred)
import Viewer exposing (Viewer)


type Session
    = LoggedIn Viewer
    | Guest


viewer : Session -> Maybe Viewer
viewer session =
    case session of
        LoggedIn val ->
            Just val

        Guest ->
            Nothing


cred : Session -> Maybe Cred
cred session =
    case session of
        LoggedIn val ->
            Just (Viewer.cred val)

        Guest ->
            Nothing



-- CHANGES


changes : (Session -> msg) -> Sub msg
changes toMsg =
    Api.viewerChanges
        (\maybeViewer -> toMsg (fromViewer maybeViewer))
        Viewer.decoder


fromViewer : Maybe Viewer -> Session
fromViewer maybeViewer =
    case maybeViewer of
        Just tok ->
            LoggedIn tok

        Nothing ->
            Guest
