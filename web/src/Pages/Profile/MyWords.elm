module Pages.Profile.MyWords exposing (Params, Model, Msg, page)

import Api
import Api.Config as Config exposing (Config)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Html exposing (..)
import Html.Attributes exposing (id)
import Http
import Http.Detailed
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import User.Profile as Profile
import User.Student.Performance.Report as PerformanceReport exposing (Tab(..))
import User.Student.Profile as StudentProfile exposing (StudentProfile)
import User.Student.Profile.Help as Help exposing (StudentHelp)
import User.Student.Resource as StudentResource
import Http

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


type MyWords =
    MyWords

type alias UsernameValidation =
    { username : Maybe StudentResource.StudentUsername
    , valid : Maybe Bool
    , msg : Maybe String
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
        , consentedToResearch : Bool
        , flashcards : Maybe (List String)
        , editing : Dict String Bool
        , usernameValidation : UsernameValidation
        , performanceReportTab : PerformanceReport.Tab
        , myWords : List (MyWordsItem)
        , help : Help.StudentProfileHelp
        , errorMessage : Maybe String
        , errors : Dict String String
        }

init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        help =
            Help.init

        studentProfile =
            Profile.toStudentProfile shared.profile

        -- words =


    in
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , navKey = shared.key
        , profile = studentProfile
        , consentedToResearch = shared.researchConsent
        , flashcards = Nothing
        , editing = Dict.empty
        , usernameValidation = { username = Nothing, valid = Nothing, msg = Nothing }
        , performanceReportTab = Completion
        , myWords = []
        , help = help
        , errorMessage = Nothing
        , errors = Dict.empty
        }, Cmd.none )



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


-- updateMyWords : Session -> Config -> MyWords -> Cmd Msg
-- updateMyWords session config myWords =
--     Cmd.none

-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save (SafeModel model) shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared (SafeModel model) =
    ( SafeModel model, Cmd.none )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "MyWords"
    , body = 
        [ div []
            [ viewContent (SafeModel model)
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    div [][
        viewMyWordsIntro
        -- , viewTable -- TODO: put a `List (MyWordsItem)` here 
    ]

viewMyWordsIntro : Html Msg
viewMyWordsIntro =
    div [ id "test" ]
        [ Html.text ("My Words is a collection of words chosen by the student throughout their text"
        ++ " readings. Here we display the phrase, the context in which the phrase is used, the"
        ++ " dictionary definition, and finally the translation.") ]


viewTable : List (MyWordsItem) -> Html Msg
viewTable myWords =
    div [ id "table" ]
        [
            table [] <|
                [ tr []
                    [ th [] [ text "Phrase" ]
                    , th [] [ text "Context" ]
                    , th [] [ text "Dictionary Form" ]
                    , th [] [ text "Translation" ]
                    ]
                ]
                -- for every item in myWords make a viewMyWordsRow
                 ++ (List.map viewMyWordsRow myWords)
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
        , td [] [ viewTranslationCell item]
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


myWordsItemDecoder : Decoder MyWordsItem
myWordsItemDecoder =
    Decode.succeed MyWordsItem
        |> required "phrase" Decode.string
        |> required "context" Decode.string
        |> required "lemma" Decode.string
        |> required "translation" Decode.string

-- what's the best way to divy up the four decoders