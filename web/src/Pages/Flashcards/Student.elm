module Pages.Flashcards.Student exposing (Model, Msg, Params, page)

import Api
import Api.Config as Config
import Api.WebSocket as WebSocket
import Flashcard.Decode
import Flashcard.Mode exposing (Mode)
import Flashcard.Model as FlashcardModel exposing (..)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick, onDoubleClick, onInput)
import Json.Decode
import Json.Encode as Encode exposing (Value)
import Role exposing (Role(..))
import Session
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.Profile
import Utils
import Viewer


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



-- INIT


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { profile : User.Profile.Profile
        , mode : Maybe Mode
        , session_state : SessionState
        , exception : Maybe Exception
        , connect : Bool
        , answer : String
        , selected_quality : Maybe Int
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { exception = Nothing
        , profile = shared.profile
        , mode = Nothing
        , session_state = Loading
        , connect = True
        , answer = ""
        , selected_quality = Nothing
        }
    , case Session.viewer shared.session of
        Just viewer ->
            Api.websocketConnect
                { name = "flashcard"
                , address =
                    WebSocket.flashcards
                        (Config.websocketBaseUrl shared.config)
                        (Viewer.role viewer)
                }
                (Session.cred shared.session)

        Nothing ->
            Cmd.none
    )



-- UPDATE


type Msg
    = SelectMode Flashcard.Mode.Mode
    | Start
    | ReviewAnswer
    | Next
    | Prev
    | InputAnswer String
    | SubmitAnswer
    | RateQuality Int
    | WebSocketResp (Result Json.Decode.Error WebSocket.WebSocketMsg)
    | Logout


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
        WebSocketResp response ->
            case response of
                Ok websocketMsg ->
                    handleWebsocketResponse (SafeModel model) websocketMsg

                Err err ->
                    webSocketError (SafeModel model) "invalid websocket msg" (Json.Decode.errorToString err)

        SelectMode mode ->
            ( SafeModel model, sendCommand (ChooseModeReq mode) )

        Start ->
            ( SafeModel model, sendCommand StartReq )

        ReviewAnswer ->
            ( SafeModel model, sendCommand ReviewAnswerReq )

        Prev ->
            ( SafeModel (FlashcardModel.setQuality model Nothing), sendCommand PrevReq )

        Next ->
            ( SafeModel (FlashcardModel.setQuality model Nothing), sendCommand NextReq )

        InputAnswer str ->
            ( SafeModel { model | answer = str }, Cmd.none )

        SubmitAnswer ->
            ( SafeModel model, sendCommand (AnswerReq model.answer) )

        RateQuality q ->
            ( SafeModel (FlashcardModel.setQuality model (Just q)), sendCommand (RateQualityReq q) )

        Logout ->
            ( SafeModel model, Api.logout () )


routeCommandResponse : SafeModel -> Maybe Mode -> CmdResp -> ( SafeModel, Cmd Msg )
routeCommandResponse (SafeModel orig_model) mode cmd_resp =
    let
        model =
            FlashcardModel.setMode orig_model mode
    in
    case cmd_resp of
        InitResp resp ->
            ( SafeModel <| FlashcardModel.setSessionState model (Init resp), Cmd.none )

        ChooseModeChoiceResp choices ->
            ( SafeModel <| FlashcardModel.setSessionState model (ViewModeChoices choices), Cmd.none )

        ReviewCardAndAnswerResp card ->
            ( SafeModel <| FlashcardModel.setSessionState model (ReviewCardAndAnswer card), Cmd.none )

        ReviewedCardAndAnsweredCorrectlyResp card ->
            ( SafeModel <| FlashcardModel.setSessionState model (ReviewedCardAndAnsweredCorrectly card), Cmd.none )

        ReviewedCardAndAnsweredIncorrectlyResp card ->
            ( SafeModel <| FlashcardModel.setSessionState model (ReviewedCardAndAnsweredIncorrectly card), Cmd.none )

        RatedCardResp card ->
            ( SafeModel <| FlashcardModel.setSessionState model (RatedCard card), Cmd.none )

        ReviewCardResp card ->
            ( SafeModel <| FlashcardModel.setSessionState model (ReviewCard card), Cmd.none )

        ReviewedCardResp card ->
            ( SafeModel <| FlashcardModel.setSessionState model (ReviewedCard card), Cmd.none )

        FinishedReviewResp ->
            ( SafeModel <| FlashcardModel.disconnect (FlashcardModel.setSessionState model FinishedReview)
            , Api.websocketDisconnect "flashcard"
            )

        ExceptionResp exception ->
            ( SafeModel <| FlashcardModel.setException model (Just exception), Cmd.none )


handleWebsocketResponse : SafeModel -> WebSocket.WebSocketMsg -> ( SafeModel, Cmd Msg )
handleWebsocketResponse safeModel websocket_resp =
    case websocket_resp of
        WebSocket.Data { data } ->
            decodeWebSocketResp safeModel data

        WebSocket.Error { error } ->
            webSocketError safeModel "websocket error" error


decodeWebSocketResp : SafeModel -> String -> ( SafeModel, Cmd Msg )
decodeWebSocketResp safeModel str =
    case Json.Decode.decodeString Flashcard.Decode.ws_resp_decoder str of
        Ok ( mode, cmd_resp ) ->
            routeCommandResponse safeModel mode cmd_resp

        Err err ->
            webSocketError safeModel "websocket decode error" (Json.Decode.errorToString err ++ " while decoding " ++ str)


webSocketError : SafeModel -> String -> String -> ( SafeModel, Cmd Msg )
webSocketError model errorType error =
    let
        _ =
            Debug.log errorType error
    in
    ( model, Cmd.none )



-- ENCODE


encodeCommand : CmdReq -> Value
encodeCommand cmdReq =
    case cmdReq of
        ChooseModeReq mode ->
            Encode.object
                [ ( "command", Encode.string "choose_mode" )
                , ( "mode", Encode.string (Flashcard.Mode.modeId mode) )
                ]

        NextReq ->
            Encode.object
                [ ( "command", Encode.string "next" )
                ]

        StartReq ->
            Encode.object
                [ ( "command", Encode.string "start" )
                ]

        ReviewAnswerReq ->
            Encode.object
                [ ( "command", Encode.string "review_answer" )
                ]

        AnswerReq answer ->
            Encode.object
                [ ( "command", Encode.string "answer" )
                , ( "answer", Encode.string answer )
                ]

        RateQualityReq q ->
            Encode.object
                [ ( "command", Encode.string "rate_quality" )
                , ( "rating", Encode.int q )
                ]

        _ ->
            Encode.object []



-- VIEW


view : SafeModel -> Document Msg
view safeModel =
    { title = "Practice Flashcards"
    , body =
        [ div []
            [ viewContent safeModel
            ]
        ]
    }


viewContent : SafeModel -> Html Msg
viewContent (SafeModel model) =
    let
        content =
            case model.session_state of
                Loading ->
                    [ div [ id "loading" ] [] ]

                Init resp ->
                    [ div [ id "loading" ]
                        [ if List.length resp.flashcards == 0 then
                            Html.text "You do not have any flashcards.  Read some more texts and add flashcards before continuing."

                          else
                            Html.text ""
                        ]
                    ]

                ViewModeChoices choices ->
                    [ viewModeChoices choices
                    , viewAdditionalNotes
                    , viewNav (SafeModel model)
                        [ viewStartNav
                        ]
                    ]

                ReviewCard card ->
                    [ viewReviewOnlyCard card
                    , viewReviewNav (SafeModel model)
                    ]

                ReviewCardAndAnswer card ->
                    [ viewReviewAndAnswerCard card
                    , viewReviewAndAnswerNav (SafeModel model)
                    ]

                ReviewedCardAndAnsweredCorrectly card ->
                    [ viewReviewedAndAnsweredCard (SafeModel model) card True
                    , viewReviewAndAnswerNav (SafeModel model)
                    ]

                ReviewedCardAndAnsweredIncorrectly card ->
                    [ viewReviewedAndAnsweredCard (SafeModel model) card False
                    , viewReviewAndAnswerNav (SafeModel model)
                    ]

                RatedCard card ->
                    [ viewRatedCard (SafeModel model) card
                    , viewReviewAndAnswerNav (SafeModel model)
                    ]

                ReviewedCard card ->
                    [ viewReviewedOnlyCard card
                    , viewReviewNav (SafeModel model)
                    ]

                FinishedReview ->
                    [ viewFinishReview
                    ]
    in
    div [ id "flashcard" ]
        [ div [ id "contents" ] content
        ]



-- VIEW: MODE


viewModeChoices : List Flashcard.Mode.ModeChoiceDesc -> Html Msg
viewModeChoices modeChoices =
    div [ id "mode-choices" ] (List.map viewModeChoice modeChoices)


viewModeChoice : Flashcard.Mode.ModeChoiceDesc -> Html Msg
viewModeChoice choice =
    div
        [ classList [ ( "mode-choice", True ), ( "cursor", True ), ( "selected", choice.selected ) ]
        , onClick (SelectMode choice.mode)
        ]
        [ div [ class "name" ] [ Html.text (Flashcard.Mode.modeName choice.mode) ]
        , div [ class "desc" ] [ Html.text choice.desc ]
        , div [ class "select" ]
            [ Html.img
                [ attribute "src" "/static/img/circle_check.svg"
                , attribute "height" "40px"
                , attribute "width" "50px"
                ]
                []
            ]
        ]


viewMode : SafeModel -> Html Msg
viewMode (SafeModel model) =
    let
        modeName =
            case model.mode of
                Just m ->
                    Flashcard.Mode.modeName m

                Nothing ->
                    "None"
    in
    div [ id "mode" ] [ Html.text (modeName ++ " Mode") ]


viewAdditionalNotes : Html Msg
viewAdditionalNotes =
    div [ id "notes" ]
        [ Html.text "Note: In review mode double-click a flashcard in order to reveal the answer."
        ]



-- VIEW: NAV


viewNav : SafeModel -> List (Html Msg) -> Html Msg
viewNav (SafeModel model) content =
    div [ id "nav" ]
        (content
            ++ (if FlashcardModel.hasException model then
                    [ viewException (SafeModel model) ]

                else
                    []
               )
        )


viewReviewAndAnswerNav : SafeModel -> Html Msg
viewReviewAndAnswerNav (SafeModel model) =
    viewNav (SafeModel model) <|
        [ viewMode (SafeModel model)
        ]
            ++ (if FlashcardModel.inReview model then
                    [ viewNextNav ]

                else
                    []
               )


viewReviewNav : SafeModel -> Html Msg
viewReviewNav (SafeModel model) =
    viewNav (SafeModel model) <|
        [ viewMode (SafeModel model)
        ]
            ++ (if FlashcardModel.inReview model then
                    [ viewPrevNav, viewNextNav ]

                else
                    []
               )


viewStartNav : Html Msg
viewStartNav =
    div [ id "start", class "cursor", onClick Start ]
        [ Html.text "Start"
        ]


viewPrevNav : Html Msg
viewPrevNav =
    div [ id "prev", class "cursor", onClick Prev ]
        [ Html.img [ attribute "src" "/static/img/angle-left.svg" ] []
        ]


viewNextNav : Html Msg
viewNextNav =
    div [ id "next", class "cursor", onClick Next ]
        [ Html.img [ attribute "src" "/static/img/angle-right.svg" ] []
        ]



-- VIEW: CARD


viewCard : Flashcard -> Maybe (List ( String, Bool )) -> Maybe (List (Html.Attribute Msg)) -> List (Html Msg) -> Html Msg
viewCard _ additionalClasses additionalAttributes content =
    div
        ([ id "card"
         , classList
            ([ ( "cursor", True ), ( "noselect", True ) ]
                ++ Maybe.withDefault [] additionalClasses
            )
         ]
            ++ Maybe.withDefault [] additionalAttributes
        )
        content


viewReviewOnlyCard : Flashcard -> Html Msg
viewReviewOnlyCard card =
    viewCard
        card
        Nothing
        (Just [ onDoubleClick ReviewAnswer ])
        [ viewPhrase card
        , viewExample card
        ]


viewReviewedOnlyCard : Flashcard -> Html Msg
viewReviewedOnlyCard card =
    viewCard
        card
        (Just [ ( "flip", True ) ])
        Nothing
        [ viewPhrase card
        , viewExample card
        ]


viewExample : Flashcard -> Html Msg
viewExample card =
    div [ id "example" ]
        [ div [] [ Html.text "e.g., " ]
        , div [ id "sentence" ] [ Html.text (FlashcardModel.example card) ]
        ]


viewPhrase : Flashcard -> Html Msg
viewPhrase card =
    div [ id "phrase" ] [ Html.text (FlashcardModel.translationOrPhrase card) ]


viewInputAnswer : Html Msg
viewInputAnswer =
    div [ id "answer_input", Utils.onEnterUp SubmitAnswer ]
        [ Html.input [ onInput InputAnswer, attribute "placeholder" "Type an answer.." ] []
        , div [ id "submit" ]
            [ div [ id "button", onClick SubmitAnswer ] [ Html.text "Submit" ]
            ]
        ]



-- VIEW: RATE


viewRateAnswer : SafeModel -> Flashcard -> Html Msg
viewRateAnswer safeModel card =
    div [ id "answer-quality" ]
        [ Html.text """Rate the difficulty of this card."""
        , div [ id "choices" ] (List.map (viewQuality safeModel card) (List.range 0 5))
        ]


viewRatedCard : SafeModel -> Flashcard -> Html Msg
viewRatedCard (SafeModel model) card =
    let
        rating =
            Maybe.withDefault "none" <| Maybe.map String.fromInt model.selected_quality
    in
    viewCard
        card
        Nothing
        Nothing
        [ viewPhrase card
        , viewExample card
        , div [ id "card_rating" ] [ Html.text ("Rated " ++ rating) ]
        ]


viewReviewedAndAnsweredCard : SafeModel -> Flashcard -> Bool -> Html Msg
viewReviewedAndAnsweredCard safeModel card answered_correctly =
    viewCard card (Just [ ( "flip", True ) ]) Nothing <|
        [ viewPhrase card
        , viewExample card
        ]
            ++ (if answered_correctly then
                    [ viewRateAnswer safeModel card ]

                else
                    []
               )


viewReviewAndAnswerCard : Flashcard -> Html Msg
viewReviewAndAnswerCard card =
    viewCard
        card
        Nothing
        Nothing
        [ viewPhrase card
        , viewExample card
        , viewInputAnswer
        ]


viewQuality : SafeModel -> Flashcard -> Int -> Html Msg
viewQuality (SafeModel model) _ q =
    let
        selected =
            case model.selected_quality of
                Just quality ->
                    quality == q

                Nothing ->
                    False
    in
    div [ classList [ ( "choice", True ), ( "select", selected ) ], onClick (RateQuality q) ] <|
        [ Html.text (String.fromInt q)
        ]
            ++ (if q == 0 then
                    [ Html.text " - most difficult" ]

                else if q == 5 then
                    [ Html.text " - easiest" ]

                else
                    []
               )


viewFinishReview : Html Msg
viewFinishReview =
    div [ id "finished" ]
        [ div [] [ Html.text "You've finished this session.  Great job.  Come back tomorrow!" ]
        ]



-- VIEW: EXCEPTION


viewException : SafeModel -> Html Msg
viewException (SafeModel model) =
    div [ id "exception" ]
        [ Html.text
            (case model.exception of
                Just exp ->
                    exp.error_msg

                _ ->
                    ""
            )
        ]



-- SHARED


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    if model.connect then
        Api.websocketReceive WebSocketResp

    else
        Sub.none
