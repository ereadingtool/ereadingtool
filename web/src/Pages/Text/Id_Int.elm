module Pages.Text.Id_Int exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint exposing (word)
import Api.WebSocket as WebSocket
import Array exposing (Array)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onMouseLeave)
import Html.Parser
import Html.Parser.Util
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Role exposing (Role(..))
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Text.Section.Words.Tag
import Text.Translations exposing (TextGroupDetails)
import TextReader.Answer.Model exposing (TextAnswer)
import TextReader.Model exposing (..)
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Section.Decode
import TextReader.Section.Model exposing (Section, TextSection, Words)
import TextReader.Text.Decode
import TextReader.Text.Model exposing (Text)
import TextReader.TextWord
import User.Profile exposing (Profile)
import User.Profile.TextReader.Flashcards
import Viewer
import Views


page : Page Params Model Msg
page =
    Page.protectedApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }


type Progress
    = Init
    | ViewIntro
    | ViewSection Section
    | Complete TextScores



-- INIT


type alias Params =
    { id : Int }


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { session : Session
        , config : Config
        , navKey : Key
        , id : Int
        , text : Text
        , profile : User.Profile.Profile
        , flashcard : User.Profile.TextReader.Flashcards.ProfileFlashcards
        , progress : Progress
        , gloss : Gloss
        , exception : Maybe Exception
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        textWordsWithFlashcards =
            -- Note: Flashcards have been deactivated. We will want to request them from
            -- an endpoint instead of from flags if we bring them back.
            -- List.map TextReader.TextWord.newFromParams flags.flashcards
            List.map TextReader.TextWord.newFromParams []

        flashcards =
            User.Profile.TextReader.Flashcards.initFlashcards
                shared.profile
                (Dict.fromList <|
                    List.map (\textWord -> ( TextReader.TextWord.phrase textWord, textWord )) textWordsWithFlashcards
                )
    in
    ( SafeModel
        { session = shared.session
        , config = shared.config
        , navKey = shared.key
        , id = params.id
        , text = TextReader.Text.Model.emptyText
        , gloss = Dict.empty
        , profile = shared.profile
        , flashcard = flashcards
        , exception = Nothing
        , progress = Init
        }
    , case Session.viewer shared.session of
        Just viewer ->
            Api.websocketConnect
                { name = "textreader"
                , address =
                    WebSocket.textReader
                        (Config.websocketBaseUrl shared.config)
                        (Viewer.role viewer)
                        params.id
                }
                (Session.cred shared.session)

        Nothing ->
            Cmd.none
    )



-- UPDATE


type Msg
    = Select TextAnswer
    | ViewFeedback Section TextQuestion TextAnswer Bool
    | PrevSection
    | NextSection
    | Gloss TextReaderWord
    | UnGloss TextReaderWord
    | ToggleGloss TextReaderWord
    | AddToFlashcards TextReaderWord
    | RemoveFromFlashcards TextReaderWord
    | WebSocketResponse (Result Json.Decode.Error WebSocket.WebSocketMsg)
    | Logout


type CommandRequest
    = NextRequest
    | PreviousRequest
    | AnswerRequest TextAnswer
    | AddToFlashcardsRequest TextReaderWord
    | RemoveFromFlashcardsRequest TextReaderWord


type CommandResponse
    = StartResponse Text
    | InProgressResponse Section
    | CompleteResponse TextScores
    | AddToFlashcardsResponse TextReader.TextWord.TextWord
    | RemoveFromFlashcardsResponse TextReader.TextWord.TextWord
    | ExceptionResponse Exception


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    let
        sendCommand =
            \commandRequest ->
                Api.websocketSend
                    { name = "textreader"
                    , content = encodeCommand commandRequest
                    }
    in
    case msg of
        Gloss reader_word ->
            ( SafeModel { model | gloss = TextReader.Model.gloss reader_word Dict.empty }
            , Cmd.none
            )

        UnGloss reader_word ->
            ( SafeModel { model | gloss = TextReader.Model.ungloss reader_word model.gloss }
            , Cmd.none
            )

        ToggleGloss reader_word ->
            ( SafeModel { model | gloss = TextReader.Model.toggleGloss reader_word model.gloss }
            , Cmd.none
            )

        AddToFlashcards reader_word ->
            ( SafeModel model
            , sendCommand <| AddToFlashcardsRequest reader_word
            )

        RemoveFromFlashcards reader_word ->
            ( SafeModel model
            , sendCommand <| RemoveFromFlashcardsRequest reader_word
            )

        Select textAnswer ->
            ( SafeModel model
            , sendCommand <| AnswerRequest textAnswer
            )

        ViewFeedback _ _ _ _ ->
            ( SafeModel model
            , Cmd.none
            )

        NextSection ->
            ( SafeModel model
            , sendCommand NextRequest
            )

        PrevSection ->
            ( SafeModel model
            , sendCommand PreviousRequest
            )

        WebSocketResponse (Ok response) ->
            handleWebsocketResponse (SafeModel model) response

        WebSocketResponse (Err _) ->
            ( SafeModel model, Cmd.none )

        Logout ->
            ( SafeModel model
            , Api.logout ()
            )


routeCommandResponse : SafeModel -> CommandResponse -> ( SafeModel, Cmd Msg )
routeCommandResponse (SafeModel model) commandResponse =
    case commandResponse of
        StartResponse text ->
            ( SafeModel { model | text = text, exception = Nothing, progress = ViewIntro }, Cmd.none )

        InProgressResponse section ->
            ( SafeModel { model | exception = Nothing, progress = ViewSection section }, Cmd.none )

        CompleteResponse text_scores ->
            ( SafeModel { model | exception = Nothing, progress = Complete text_scores }, Cmd.none )

        AddToFlashcardsResponse textWord ->
            ( SafeModel { model | flashcard = User.Profile.TextReader.Flashcards.addFlashcard model.flashcard textWord }, Cmd.none )

        RemoveFromFlashcardsResponse textWord ->
            ( SafeModel { model | flashcard = User.Profile.TextReader.Flashcards.removeFlashcard model.flashcard textWord }, Cmd.none )

        ExceptionResponse exception ->
            ( SafeModel { model | exception = Just exception }, Cmd.none )


handleWebsocketResponse : SafeModel -> WebSocket.WebSocketMsg -> ( SafeModel, Cmd Msg )
handleWebsocketResponse (SafeModel model) message =
    case message of
        WebSocket.Data { name, data } ->
            case Json.Decode.decodeString wsRespDecoder data of
                Ok commandResponse ->
                    routeCommandResponse (SafeModel model) commandResponse

                Err err ->
                    let
                        _ =
                            Debug.log "websocket decode error" err
                    in
                    ( SafeModel model, Cmd.none )

        WebSocket.Error err ->
            let
                _ =
                    Debug.log "server error response" err
            in
            ( SafeModel model, Cmd.none )



-- ENCODE


encodeCommand : CommandRequest -> Value
encodeCommand commandRequest =
    case commandRequest of
        NextRequest ->
            Encode.object
                [ ( "command", Encode.string "next" )
                ]

        PreviousRequest ->
            Encode.object
                [ ( "command", Encode.string "prev" )
                ]

        AnswerRequest textAnswer ->
            let
                textReaderAnswer =
                    TextReader.Answer.Model.answer textAnswer
            in
            Encode.object
                [ ( "command", Encode.string "answer" )
                , ( "answer_id", Encode.int textReaderAnswer.id )
                ]

        AddToFlashcardsRequest reader_word ->
            Encode.object
                [ ( "command", Encode.string "add_flashcard_phrase" )
                , ( "instance", Encode.string (String.fromInt (TextReader.Model.instance reader_word)) )
                , ( "phrase", Encode.string (TextReader.Model.phrase reader_word) )
                ]

        RemoveFromFlashcardsRequest reader_word ->
            Encode.object
                [ ( "command", Encode.string "remove_flashcard_phrase" )
                , ( "instance", Encode.string (String.fromInt (TextReader.Model.instance reader_word)) )
                , ( "phrase", Encode.string (TextReader.Model.phrase reader_word) )
                ]



-- DECODE


wsRespDecoder : Json.Decode.Decoder CommandResponse
wsRespDecoder =
    Json.Decode.field "command" Json.Decode.string |> Json.Decode.andThen commandRespDecoder


commandRespDecoder : String -> Json.Decode.Decoder CommandResponse
commandRespDecoder cmdStr =
    case cmdStr of
        "intro" ->
            startDecoder

        "in_progress" ->
            sectionDecoder InProgressResponse

        "exception" ->
            Json.Decode.map ExceptionResponse (Json.Decode.field "result" exceptionDecoder)

        "complete" ->
            Json.Decode.map CompleteResponse (Json.Decode.field "result" textScoresDecoder)

        "add_flashcard_phrase" ->
            Json.Decode.map
                AddToFlashcardsResponse
                (Json.Decode.field "result" TextReader.Section.Decode.textWordInstanceDecoder)

        "remove_flashcard_phrase" ->
            Json.Decode.map
                RemoveFromFlashcardsResponse
                (Json.Decode.field "result" TextReader.Section.Decode.textWordInstanceDecoder)

        _ ->
            Json.Decode.fail ("Command " ++ cmdStr ++ " not supported")


startDecoder : Json.Decode.Decoder CommandResponse
startDecoder =
    Json.Decode.map StartResponse (Json.Decode.field "result" TextReader.Text.Decode.textDecoder)


sectionDecoder : (Section -> CommandResponse) -> Json.Decode.Decoder CommandResponse
sectionDecoder commandResponse =
    Json.Decode.map commandResponse (Json.Decode.field "result" TextReader.Section.Decode.sectionDecoder)


exceptionDecoder : Json.Decode.Decoder Exception
exceptionDecoder =
    Json.Decode.succeed Exception
        |> required "code" Json.Decode.string
        |> required "error_msg" Json.Decode.string


textScoresDecoder : Json.Decode.Decoder TextScores
textScoresDecoder =
    Json.Decode.succeed TextScores
        |> required "num_of_sections" Json.Decode.int
        |> required "complete_sections" Json.Decode.int
        |> required "section_scores" Json.Decode.int
        |> required "possible_section_scores" Json.Decode.int



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "Reading | " ++ String.fromInt model.id

    {- This would be better, but we need to add title to all websocket
       responses
    -}
    -- if String.isEmpty model.text.title then
    --     "Reading"
    -- else
    --     "Reading | " ++ model.text.title
    , body =
        [ div []
            [ viewContent (SafeModel model)
            , Views.view_footer
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    let
        content =
            case model.progress of
                ViewIntro ->
                    [ viewTextIntroduction model.text
                    , div [ id "nav", onClick NextSection ]
                        [ div [ class "start-btn" ] [ Html.text "Start" ]
                        ]
                    ]

                ViewSection section ->
                    [ viewTextSection (SafeModel model) section
                    , viewExceptions (SafeModel model)
                    , div [ id "nav" ] [ viewPreviousButton, viewNextButton ]
                    ]

                Complete text_scores ->
                    [ viewTextComplete (SafeModel model) text_scores ]

                _ ->
                    []
    in
    div [ id "text-section" ] content



-- VIEW: INTRODUCTION


viewTextIntroduction : Text -> Html Msg
viewTextIntroduction text =
    div [ attribute "id" "text-intro" ] <|
        htmlNode text.introduction



-- VIEW: SECTION


viewTextSection : SafeModel -> Section -> Html Msg
viewTextSection (SafeModel model) textReaderSection =
    let
        textSection =
            TextReader.Section.Model.textSection textReaderSection

        textBodyVdom =
            case Html.Parser.run textSection.body of
                Ok nodes ->
                    Text.Section.Words.Tag.toTaggedHtml
                        { tagWord = tagWord (SafeModel model) textReaderSection
                        , inCompoundWord = inCompoundWord textReaderSection
                        , nodes = nodes
                        }

                Err err ->
                    [ Html.text "Error processing text. Please contact us for help." ]

        section_title =
            "Section " ++ String.fromInt (textSection.order + 1) ++ "/" ++ String.fromInt textSection.num_of_sections
    in
    div [ id "text-body" ] <|
        [ div [ id "title" ] [ Html.text section_title ]
        , div [ id "text" ] textBodyVdom
        , viewQuestions textReaderSection
        ]


tagWord :
    SafeModel
    -> Section
    -> Int
    -> { leadingPunctuation : String, token : String, trailingPunctuation : String }
    -> Html Msg
tagWord (SafeModel model) textReaderSection instance wordRecord =
    let
        id =
            String.join "_" [ String.fromInt instance, wordRecord.token ]

        textreaderTextword =
            TextReader.Section.Model.getTextWord textReaderSection instance wordRecord.token

        readerWord =
            TextReader.Model.new id instance wordRecord.token textreaderTextword
    in
    if wordRecord.token == " " then
        Html.text " "

    else
        case textreaderTextword of
            Just text_word ->
                if TextReader.TextWord.hasTranslations text_word then
                    viewDefinedWord (SafeModel model) readerWord text_word wordRecord

                else
                    Html.text (wordRecord.leadingPunctuation ++ wordRecord.token ++ wordRecord.trailingPunctuation)

            Nothing ->
                Html.text (wordRecord.leadingPunctuation ++ wordRecord.token ++ wordRecord.trailingPunctuation)


inCompoundWord : Section -> Int -> String -> Maybe TextGroupDetails
inCompoundWord section instance word =
    case TextReader.Section.Model.getTextWord section instance word of
        Just textWord ->
            TextReader.TextWord.group textWord

        Nothing ->
            Nothing


viewQuestions : Section -> Html Msg
viewQuestions section =
    let
        text_reader_questions =
            TextReader.Section.Model.questions section
    in
    div [ id "questions" ] (Array.toList <| Array.map (viewQuestion section) text_reader_questions)


viewQuestion : Section -> TextQuestion -> Html Msg
viewQuestion textSection textQuestion =
    let
        question =
            TextReader.Question.Model.question textQuestion

        answers =
            TextReader.Question.Model.answers textQuestion

        textQuestionId =
            String.join "_" [ "question", String.fromInt question.order ]
    in
    div [ class "reader-question", attribute "id" textQuestionId ]
        [ div [ class "question-body" ] [ Html.text question.body ]
        , div [ class "answers" ]
            (Array.toList <| Array.map (viewAnswer textSection textQuestion) answers)
        ]


viewAnswer : Section -> TextQuestion -> TextAnswer -> Html Msg
viewAnswer textSection textQuestion textAnswer =
    let
        questionAnswered =
            TextReader.Question.Model.answered textQuestion

        onclick =
            if questionAnswered then
                onClick (ViewFeedback textSection textQuestion textAnswer True)

            else
                onClick (Select textAnswer)

        answer =
            TextReader.Answer.Model.answer textAnswer

        answerSelected =
            TextReader.Answer.Model.selected textAnswer

        isCorrect =
            TextReader.Answer.Model.correct textAnswer

        viewFeedback =
            TextReader.Answer.Model.feedback_viewable textAnswer
    in
    div
        [ classList <|
            [ ( "answer", True )
            , ( "answer-selected", answerSelected )
            ]
                ++ (if answerSelected || viewFeedback then
                        if isCorrect then
                            [ ( "correct", isCorrect ) ]

                        else
                            [ ( "incorrect", not isCorrect ) ]

                    else
                        []
                   )
        , onclick
        ]
        [ div [ classList [ ( "answer-text", True ), ( "bolder", answerSelected ) ] ] [ Html.text answer.text ]
        , if answerSelected || viewFeedback then
            div [ class "answer-feedback" ] [ Html.em [] [ Html.text answer.feedback ] ]

          else
            Html.text ""
        ]


viewExceptions : SafeModel -> Html Msg
viewExceptions (SafeModel model) =
    div [ class "exception" ]
        (case model.exception of
            Just exception ->
                [ Html.text exception.error_msg
                ]

            Nothing ->
                []
        )


viewPreviousButton : Html Msg
viewPreviousButton =
    div [ onClick PrevSection, class "prev-btn" ]
        [ Html.text "Previous"
        ]


viewNextButton : Html Msg
viewNextButton =
    div [ onClick NextSection, class "next-btn" ]
        [ Html.text "Next"
        ]



-- VIEW: CONCLUSION


viewTextComplete : SafeModel -> TextScores -> Html Msg
viewTextComplete (SafeModel model) scores =
    div [ id "complete" ]
        [ div [ attribute "id" "text-score" ]
            [ div []
                [ Html.text
                    ("You answered "
                        ++ String.fromInt scores.section_scores
                        ++ " out of "
                        ++ String.fromInt scores.possible_section_scores
                        ++ " questions correctly for this text."
                    )
                ]
            ]
        , viewTextConclusion model.text
        , div [ id "nav" ]
            [ viewPreviousButton
            , Html.a
                [ attribute "href" (Route.toString (Route.Text__Id_Int { id = model.id }))
                ]
                [ span [] [ Html.text "Read Again" ]
                ]
            , Html.a [ attribute "href" (Route.toString Route.Text__Search) ] [ span [] [ Html.text "Read Another Text" ] ]
            ]
        ]


viewTextConclusion : Text -> Html Msg
viewTextConclusion text =
    div [ attribute "id" "text-conclusion" ] <|
        htmlNode (Maybe.withDefault "" text.conclusion)



-- VIEW: WORD


viewDefinedWord :
    SafeModel
    -> TextReader.Model.TextReaderWord
    -> TextReader.TextWord.TextWord
    -> { leadingPunctuation : String, token : String, trailingPunctuation : String }
    -> Html Msg
viewDefinedWord (SafeModel model) reader_word text_word wordRecord =
    Html.node "span"
        [ onClick (ToggleGloss reader_word)
        , class "word-block"
        ]
        [ span [] [ Html.text wordRecord.leadingPunctuation ]
        , span
            [ classList
                [ ( "highlighted", TextReader.Model.glossed reader_word model.gloss )
                , ( "cursor", True )
                ]
            ]
            [ Html.text wordRecord.token
            ]
        , viewGloss (SafeModel model) reader_word text_word
        , span [] [ Html.text wordRecord.trailingPunctuation ]
        ]


viewGloss : SafeModel -> TextReaderWord -> TextReader.TextWord.TextWord -> Html Msg
viewGloss (SafeModel model) reader_word text_word =
    span []
        [ span
            [ classList [ ( "gloss-overlay", True ), ( "gloss-menu", True ) ]
            , onMouseLeave (UnGloss reader_word)
            , classList [ ( "hidden", not (TextReader.Model.selected reader_word model.gloss) ) ]
            ]
            [ viewWordAndGrammemes reader_word text_word
            , viewTranslations (TextReader.TextWord.translations text_word)
            , viewFlashcardOptions (SafeModel model) reader_word
            ]
        ]


viewWordAndGrammemes : TextReaderWord -> TextReader.TextWord.TextWord -> Html Msg
viewWordAndGrammemes reader_word text_word =
    let
        lemma =
            TextReader.TextWord.lemma text_word

        displayedWord =
            if not (String.isEmpty lemma) then
                lemma

            else
                TextReader.Model.phrase reader_word

        grammemes =
            TextReader.TextWord.grammemesToString text_word
    in
    div []
        [ Html.text <|
            displayedWord
                ++ (if not (String.isEmpty grammemes) then
                        " (" ++ grammemes ++ ")"

                    else
                        ""
                   )
        ]


viewTranslations : Maybe (List TextReader.TextWord.Translation) -> Html Msg
viewTranslations defs =
    div [ class "translations" ]
        (case defs of
            Just translations ->
                List.map view_translation (List.filter (\tr -> tr.correct_for_context) translations)

            Nothing ->
                []
        )


view_translation : TextReader.TextWord.Translation -> Html Msg
view_translation translation =
    div [ class "translation" ] [ Html.text translation.text ]


viewFlashcardOptions : SafeModel -> TextReaderWord -> Html Msg
viewFlashcardOptions (SafeModel model) reader_word =
    let
        phrase =
            TextReader.Model.phrase reader_word

        translations =
            Maybe.map
                TextReader.TextWord.translations
                (TextReader.Model.textWord reader_word)

        flashcards =
            Maybe.withDefault Dict.empty (User.Profile.TextReader.Flashcards.flashcards model.flashcard)

        add =
            div [ class "cursor", onClick (AddToFlashcards reader_word) ] [ Html.text "Add to My Words" ]

        remove =
            div [ class "cursor", onClick (RemoveFromFlashcards reader_word) ] [ Html.text "Remove from My Words" ]
    in
    case Session.viewer model.session of
        Just viewer ->
            case Viewer.role viewer of
                Student ->
                    case translations of
                        Just ts ->
                            div [ class "gloss-flashcard-options" ] <|
                                if Dict.member phrase flashcards then
                                    [ remove ]

                                else
                                    [ add ]

                        Nothing ->
                            Html.text ""

                Instructor ->
                    Html.text ""

        Nothing ->
            Html.text ""


viewFlashcardWords : SafeModel -> Html Msg
viewFlashcardWords (SafeModel model) =
    div []
        (List.map (\( normal_form, text_word ) -> div [] [ Html.text normal_form ])
            (Dict.toList <| Maybe.withDefault Dict.empty <| User.Profile.TextReader.Flashcards.flashcards model.flashcard)
        )



-- VIEW : HTML NODE


htmlNode : String -> List (Html msg)
htmlNode htmlString =
    case Html.Parser.run htmlString of
        Ok node ->
            node
                |> Html.Parser.Util.toVirtualDom

        Err err ->
            [ Html.text "Error processing text. Please contact us for help." ]



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : SafeModel -> Sub Msg
subscriptions _ =
    Api.websocketReceive
        (\websocketMessage ->
            WebSocketResponse websocketMessage
        )
