module Spa.Page exposing
    ( Page
    , static, sandbox, element, application
    , protectedApplication, protectedInstructorApplication, protectedStudentApplication
    )

{-|

@docs Page
@docs static, sandbox, element, application
@docs Upgraded, Bundle, upgrade

-}

import Browser.Navigation as Nav
import Role exposing (Role)
import Session
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Url exposing (Url)


type alias Page params model msg =
    { init : Shared.Model -> Url params -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    , save : model -> Shared.Model -> Shared.Model
    , load : Shared.Model -> model -> ( model, Cmd msg )
    }


static :
    { view : Url params -> Document msg
    }
    -> Page params (Url params) msg
static page =
    { init = \_ url -> ( url, Cmd.none )
    , update = \_ model -> ( model, Cmd.none )
    , view = page.view
    , subscriptions = \_ -> Sub.none
    , save = always identity
    , load = always (identity >> ignoreEffect)
    }


sandbox :
    { init : Url params -> model
    , update : msg -> model -> model
    , view : model -> Document msg
    }
    -> Page params model msg
sandbox page =
    { init = \_ url -> ( page.init url, Cmd.none )
    , update = \msg model -> ( page.update msg model, Cmd.none )
    , view = page.view
    , subscriptions = \_ -> Sub.none
    , save = always identity
    , load = always (identity >> ignoreEffect)
    }


element :
    { init : Url params -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    }
    -> Page params model msg
element page =
    { init = \_ params -> page.init params
    , update = \msg model -> page.update msg model
    , view = page.view
    , subscriptions = page.subscriptions
    , save = always identity
    , load = always (identity >> ignoreEffect)
    }


application :
    { init : Shared.Model -> Url params -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    , save : model -> Shared.Model -> Shared.Model
    , load : Shared.Model -> model -> ( model, Cmd msg )
    }
    -> Page params model msg
application page =
    page


protectedApplication :
    { init : Shared.Model -> Url params -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    , save : model -> Shared.Model -> Shared.Model
    , load : Shared.Model -> model -> ( model, Cmd msg )
    }
    -> Page params (Maybe model) msg
protectedApplication page =
    { init =
        \shared url ->
            case Session.viewer shared.session of
                Just viewer ->
                    page.init shared url |> Tuple.mapFirst Just

                Nothing ->
                    ( Nothing
                    , Nav.pushUrl url.key (Route.toString Route.Top)
                    )
    , update =
        \msg maybeModel ->
            case maybeModel of
                Just model ->
                    page.update msg model |> Tuple.mapFirst Just

                Nothing ->
                    ( Nothing, Cmd.none )
    , view =
        \maybeModel ->
            case maybeModel of
                Just model ->
                    page.view model

                Nothing ->
                    { title = "Redirecting to login page", body = [] }
    , subscriptions =
        \maybeModel ->
            case maybeModel of
                Just model ->
                    page.subscriptions model

                Nothing ->
                    Sub.none
    , save = \_ shared -> shared
    , load =
        \shared model ->
            case Session.viewer shared.session of
                Just viewer ->
                    ( model, Cmd.none )

                Nothing ->
                    ( Nothing
                    , Nav.pushUrl shared.key (Route.toString Route.Top)
                    )
    }


protectedStudentApplication :
    { init : Shared.Model -> Url params -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    , save : model -> Shared.Model -> Shared.Model
    , load : Shared.Model -> model -> ( model, Cmd msg )
    }
    -> Page params (Maybe model) msg
protectedStudentApplication page =
    { init =
        \shared url ->
            case Session.viewer shared.session of
                Just viewer ->
                    case Session.role shared.session of
                        Just role ->
                            if Role.isStudent role then
                                page.init shared url |> Tuple.mapFirst Just

                            else
                                ( Nothing
                                , Nav.pushUrl url.key (Route.toString Route.Top)
                                )

                        Nothing ->
                            ( Nothing
                            , Nav.pushUrl url.key (Route.toString Route.Top)
                            )

                Nothing ->
                    ( Nothing
                    , Nav.pushUrl url.key (Route.toString Route.Top)
                    )
    , update =
        \msg maybeModel ->
            case maybeModel of
                Just model ->
                    page.update msg model |> Tuple.mapFirst Just

                Nothing ->
                    ( Nothing, Cmd.none )
    , view =
        \maybeModel ->
            case maybeModel of
                Just model ->
                    page.view model

                Nothing ->
                    { title = "Redirecting to login page", body = [] }
    , subscriptions =
        \maybeModel ->
            case maybeModel of
                Just model ->
                    page.subscriptions model

                Nothing ->
                    Sub.none
    , save = \_ shared -> shared
    , load =
        \shared model ->
            case Session.viewer shared.session of
                Just viewer ->
                    ( model, Cmd.none )

                Nothing ->
                    ( Nothing
                    , Nav.pushUrl shared.key (Route.toString Route.Top)
                    )
    }


protectedInstructorApplication :
    { init : Shared.Model -> Url params -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Document msg
    , subscriptions : model -> Sub msg
    , save : model -> Shared.Model -> Shared.Model
    , load : Shared.Model -> model -> ( model, Cmd msg )
    }
    -> Page params (Maybe model) msg
protectedInstructorApplication page =
    { init =
        \shared url ->
            case Session.viewer shared.session of
                Just viewer ->
                    case Session.role shared.session of
                        Just role ->
                            if Role.isInstructor role then
                                page.init shared url |> Tuple.mapFirst Just

                            else
                                ( Nothing
                                , Nav.pushUrl url.key (Route.toString Route.Top)
                                )

                        Nothing ->
                            ( Nothing
                            , Nav.pushUrl url.key (Route.toString Route.Top)
                            )

                Nothing ->
                    ( Nothing
                    , Nav.pushUrl url.key (Route.toString Route.Top)
                    )
    , update =
        \msg maybeModel ->
            case maybeModel of
                Just model ->
                    page.update msg model |> Tuple.mapFirst Just

                Nothing ->
                    ( Nothing, Cmd.none )
    , view =
        \maybeModel ->
            case maybeModel of
                Just model ->
                    page.view model

                Nothing ->
                    { title = "Redirecting to login page", body = [] }
    , subscriptions =
        \maybeModel ->
            case maybeModel of
                Just model ->
                    page.subscriptions model

                Nothing ->
                    Sub.none
    , save = \_ shared -> shared
    , load =
        \shared model ->
            case Session.viewer shared.session of
                Just viewer ->
                    ( model, Cmd.none )

                Nothing ->
                    ( Nothing
                    , Nav.pushUrl shared.key (Route.toString Route.Top)
                    )
    }


ignoreEffect : model -> ( model, Cmd msg )
ignoreEffect model =
    ( model, Cmd.none )
