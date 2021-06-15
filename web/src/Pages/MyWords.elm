module Pages.MyWords exposing (Model, Msg, MyWordsItem, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (id)
import Http
import Http.Detailed
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import User.Profile as Profile
import User.Student.Profile as StudentProfile exposing (StudentProfile)


page : Page Params Model Msg
page =
    Page.protectedStudentApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }


type alias MyWordsItem =
    { phrase : String
    , context : String
    , lemma : String
    , translation : String
    }



-- INIT


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { session : Session
        , config : Config
        , navKey : Key
        , profile : StudentProfile
        , myWords : List MyWordsItem
        , errorMessage : Maybe String
        , errors : Dict String String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        studentProfile =
            Profile.toStudentProfile shared.profile
    in
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , navKey = shared.key
        , profile = studentProfile
        , myWords = []
        , errorMessage = Nothing
        , errors = Dict.empty
        }
    , Cmd.batch
        [ case StudentProfile.studentID studentProfile of
            Just id ->
                if id /= 0 then
                    updateMyWords
                        shared.session
                        shared.config
                        (Profile.toStudentProfile shared.profile)

                else
                    Cmd.none

            Nothing ->
                Cmd.none
        , Api.websocketDisconnectAll
        ]
    )



-- UPDATE


type Msg
    = GotMyWords (Result (Http.Detailed.Error String) ( Http.Metadata, List MyWordsItem ))


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        GotMyWords (Ok ( metadata, myWords )) ->
            let
                maybeErrorMessage =
                    if List.isEmpty myWords then
                        Just ""

                    else
                        Nothing
            in
            ( SafeModel
                { model
                    | myWords = myWords
                    , errorMessage = maybeErrorMessage
                }
            , Cmd.none
            )

        GotMyWords (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    if metadata.statusCode == 403 then
                        ( SafeModel model
                        , Api.logout ()
                        )

                    else
                        ( SafeModel { model | errorMessage = Just "An error occurred.  Please contact an administrator." }
                        , Cmd.none
                        )

                _ ->
                    ( SafeModel { model | errorMessage = Just "An error occurred.  Please contact an administrator." }
                    , Cmd.none
                    )


updateMyWords : Session -> Config -> StudentProfile -> Cmd Msg
updateMyWords session config profile =
    case StudentProfile.studentID profile of
        Just studentId ->
            Api.getDetailed
                (Endpoint.myWords
                    (Config.restApiUrl config)
                 -- studentId
                )
                (Session.cred session)
                GotMyWords
                -- TODO: change the decoder
                myWordsDecoder

        Nothing ->
            Cmd.none



-- DECODE
-- TODO: make this a single decoder


myWordsDecoder : Json.Decode.Decoder (List MyWordsItem)
myWordsDecoder =
    Json.Decode.list myWordItemDecoder


myWordItemDecoder : Json.Decode.Decoder MyWordsItem
myWordItemDecoder =
    Json.Decode.succeed MyWordsItem
        |> required "phrase" Json.Decode.string
        |> required "context" Json.Decode.string
        |> required "lemma" Json.Decode.string
        |> required "translation" Json.Decode.string



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save (SafeModel model) shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared (SafeModel model) =
    ( SafeModel
        { model
            | profile = Profile.toStudentProfile shared.profile
        }
    , case StudentProfile.studentID (Profile.toStudentProfile shared.profile) of
        Just id ->
            if id /= 0 then
                updateMyWords
                    shared.session
                    shared.config
                    (Profile.toStudentProfile shared.profile)

            else
                Cmd.none

        Nothing ->
            Cmd.none
    )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "MyWords"
    , body =
        [ div [ id "my-words-box" ]
            [ div [ id "my-words-title" ] [ text "My Words" ]
            , div []
                [ viewContent (SafeModel model) ]
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div []
        [ viewMyWordsIntro
        , viewTable model.myWords -- TODO: put a `List (MyWordsItem)` here
        ]


viewMyWordsIntro : Html Msg
viewMyWordsIntro =
    div [ id "my-words-intro" ]
        [ Html.text "These are the words that have been saved to My Words." ]


viewTable : List MyWordsItem -> Html Msg
viewTable myWords =
    div [ id "my-words-table" ]
        [ table [] <|
            [ tr []
                [ th [] [ text "Phrase" ]
                , th [] [ text "Context" ]
                , th [] [ text "Dictionary Form" ]
                , th [] [ text "Translation" ]
                ]
            ]
                -- for every item in myWords make a viewMyWordsRow
                ++ List.map viewMyWordsRow myWords

        --   div [ id "my-words" ] (List.map viewMyWordsRow myWords)
        ]



-- viewMyWordsRow : MyWordsItem -> List (Html msg)


viewMyWordsRow : MyWordsItem -> Html msg
viewMyWordsRow item =
    -- [ tr []
    tr []
        [ td [] [ viewPhraseCell item ]
        , td [] [ viewContextCell item ]
        , td [] [ viewLemmaCell item ]
        , td [] [ viewTranslationCell item ]
        ]



-- ]


viewPhraseCell : MyWordsItem -> Html msg
viewPhraseCell item =
    text item.phrase


viewContextCell : MyWordsItem -> Html msg
viewContextCell item =
    text item.context


viewLemmaCell : MyWordsItem -> Html msg
viewLemmaCell item =
    text item.lemma


viewTranslationCell : MyWordsItem -> Html msg
viewTranslationCell item =
    text item.translation
