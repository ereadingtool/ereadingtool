module Pages.Text.Id_Int exposing (Model, Msg, Params, page)

-- import Http

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Array exposing (Array)
import Browser
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick, onMouseLeave)
import Html.Parser
import Html.Parser.Util
import Json.Decode
import Menu.Items
import Menu.Logout
import Menu.Msg as MenuMsg
import Ports
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Text.Section.Words.Tag
import TextReader.Answer.Model exposing (TextAnswer)
import TextReader.Decode
import TextReader.Model exposing (..)
import TextReader.Msg exposing (Msg(..))
import TextReader.Question.Model exposing (TextQuestion)
import TextReader.Section.Model exposing (Section, Words)
import TextReader.Text.Model exposing (Text)
import TextReader.TextWord
import TextReader.Update exposing (..)
import TextReader.View exposing (..)
import TextReader.WebSocket
import User.Profile exposing (Profile)
import User.Profile.TextReader.Flashcards
import Views
import WebSocket


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
        { text : Text
        , profile : User.Profile.Profile
        , flashcard : User.Profile.TextReader.Flashcards.ProfileFlashcards
        , progress : Progress
        , gloss : Gloss
        , exception : Maybe Exception

        -- , text_url : Text.Resource.TextReadingURL
        -- , flags : Flags
        -- , menu_items : Menu.Items.MenuItems
        }



-- type alias Flags =
--     Flags.Flags
--         { text_id : Int
--         , text_url : String
--         , flashcards : List TextReader.TextWord.TextWordParams
--         , text_reader_ws_addr : String
--         }


fakeProfile : Profile
fakeProfile =
    User.Profile.initProfile <|
        { student_profile =
            Just
                { id = Just 0
                , username = Just "fake name"
                , email = "test@email.com"
                , difficulty_preference = Just ( "intermediate_mid", "Intermediate-Mid" )
                , difficulties = Shared.difficulties
                , uris =
                    { logout_uri = "logout"
                    , profile_uri = "profile"
                    }
                }
        , instructor_profile = Nothing
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    let
        profile =
            --         User.Profile.initProfile flags
            fakeProfile

        --     textReaderAddr =
        --         TextReader.WebSocket.toAddress flags.text_reader_ws_addr
        text_words_with_flashcards =
            -- List.map TextReader.TextWord.newFromParams flags.flashcards
            List.map TextReader.TextWord.newFromParams []

        --     menuItems =
        --         Menu.Items.initMenuItems flags
        flashcards =
            User.Profile.TextReader.Flashcards.initFlashcards
                profile
                (Dict.fromList <|
                    List.map (\text_word -> ( TextReader.TextWord.phrase text_word, text_word )) text_words_with_flashcards
                )
    in
    ( SafeModel
        { text = TextReader.Text.Model.emptyText
        , gloss = Dict.empty
        , profile = profile
        , flashcard = flashcards
        , exception = Nothing

        --   , progress = Init
        , progress = ViewIntro

        --   , text_url = Text.Resource.TextReadingURL (Text.Resource.URL flags.text_url)
        --   , flags = flags
        --   , menu_items = menuItems
        }
      -- , TextReader.WebSocket.connect textReaderAddr ""
    , Cmd.none
    )



-- UPDATE


type Msg
    = Select TextAnswer
    | ViewFeedback Section TextQuestion TextAnswer Bool
    | PrevSection
    | NextSection
    | StartOver
    | Gloss TextReaderWord
    | UnGloss TextReaderWord
    | ToggleGloss TextReaderWord
    | AddToFlashcards TextReaderWord
    | RemoveFromFlashcards TextReaderWord
      -- | WebSocketResp (Result Json.Decode.Error WebSocket.WebSocketMsg)
    | Logout


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    let
        sendCommand =
            \cmdRequest ->
                TextReader.WebSocket.sendCommand cmdRequest
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
            , sendCommand <| AddToFlashcardsReq reader_word
            )

        RemoveFromFlashcards reader_word ->
            ( SafeModel model
            , sendCommand <| RemoveFromFlashcardsReq reader_word
            )

        Select text_answer ->
            ( SafeModel model
            , sendCommand <| AnswerReq text_answer
            )

        ViewFeedback _ _ _ _ ->
            ( SafeModel model
            , Cmd.none
            )

        StartOver ->
            ( SafeModel model
              -- , Ports.redirect (Text.Resource.textReadingURLToString model.text_url)
            , Cmd.none
            )

        NextSection ->
            ( SafeModel model
            , sendCommand NextReq
            )

        PrevSection ->
            ( SafeModel model
            , sendCommand PrevReq
            )

        -- WebSocketResp str ->
        -- TextReader.Update.handleWSResp model str
        -- handleWSResp (SafeModel model) str
        Logout ->
            ( SafeModel model
              -- , User.Profile.logout model.profile model.flags.csrftoken LoggedOut
            , Api.logout ()
            )


routeCmdResp : SafeModel -> CmdResp -> ( SafeModel, Cmd Msg )
routeCmdResp (SafeModel model) cmd_resp =
    case cmd_resp of
        StartResp text ->
            ( SafeModel { model | text = text, exception = Nothing, progress = ViewIntro }, Cmd.none )

        InProgressResp section ->
            ( SafeModel { model | exception = Nothing, progress = ViewSection section }, Cmd.none )

        CompleteResp text_scores ->
            ( SafeModel { model | exception = Nothing, progress = Complete text_scores }, Cmd.none )

        AddToFlashcardsResp text_word ->
            ( SafeModel { model | flashcard = User.Profile.TextReader.Flashcards.addFlashcard model.flashcard text_word }, Cmd.none )

        RemoveFromFlashcardsResp text_word ->
            ( SafeModel { model | flashcard = User.Profile.TextReader.Flashcards.removeFlashcard model.flashcard text_word }, Cmd.none )

        ExceptionResp exception ->
            ( SafeModel { model | exception = Just exception }, Cmd.none )


handleWSResp : SafeModel -> String -> ( SafeModel, Cmd Msg )
handleWSResp (SafeModel model) str =
    case Json.Decode.decodeString TextReader.Decode.wsRespDecoder str of
        Ok cmd_resp ->
            routeCmdResp (SafeModel model) cmd_resp

        Err err ->
            let
                _ =
                    Debug.log "websocket decode error" err
            in
            ( SafeModel model, Cmd.none )



-- VIEW


view : SafeModel -> Document Msg
view safeModel =
    -- TODO: change title to to title of text
    { title = "Text"
    , body =
        [ div []
            [ viewHeader safeModel
            , viewContent safeModel
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
                    [ view_text_introduction model.text
                    , div [ id "nav", onClick NextSection ]
                        [ div [ class "start-btn" ] [ Html.text "Start" ]
                        ]
                    ]

                ViewSection section ->
                    [ view_text_section (SafeModel model) section
                    , view_exceptions (SafeModel model)
                    , div [ id "nav" ] [ view_prev_btn, view_next_btn ]
                    ]

                Complete text_scores ->
                    [ view_text_complete (SafeModel model) text_scores ]

                _ ->
                    []
    in
    div [ id "text-section" ] content


view_text_introduction : Text -> Html Msg
view_text_introduction text =
    div [ attribute "id" "text-intro" ]
        -- (Html.Parser.Util.toVirtualDom <| Html.Parser.parse text.introduction)
        []


view_text_section : SafeModel -> Section -> Html Msg
view_text_section (SafeModel model) text_reader_section =
    let
        text_section =
            TextReader.Section.Model.textSection text_reader_section

        text_body_vdom =
            Text.Section.Words.Tag.tagWordsAndToVDOM
                (tagWord (SafeModel model) text_reader_section)
                (isPartOfCompoundWord text_reader_section)
                -- (HtmlParser.parse text_section.body)
                []

        section_title =
            "Section " ++ String.fromInt (text_section.order + 1) ++ "/" ++ String.fromInt text_section.num_of_sections
    in
    div [ id "text-body" ] <|
        [ div [ id "title" ] [ Html.text section_title ]
        , div [ id "body" ] text_body_vdom
        , view_questions text_reader_section
        ]


view_questions : Section -> Html Msg
view_questions section =
    let
        text_reader_questions =
            TextReader.Section.Model.questions section
    in
    div [ id "questions" ] (Array.toList <| Array.map (view_question section) text_reader_questions)


view_question : Section -> TextQuestion -> Html Msg
view_question text_section text_question =
    let
        question =
            TextReader.Question.Model.question text_question

        answers =
            TextReader.Question.Model.answers text_question

        text_question_id =
            String.join "_" [ "question", String.fromInt question.order ]
    in
    div [ class "question", attribute "id" text_question_id ]
        [ div [ class "question-body" ] [ Html.text question.body ]
        , div [ class "answers" ]
            (Array.toList <| Array.map (view_answer text_section text_question) answers)
        ]


view_answer : Section -> TextQuestion -> TextAnswer -> Html Msg
view_answer text_section text_question text_answer =
    let
        question_answered =
            TextReader.Question.Model.answered text_question

        on_click =
            if question_answered then
                onClick (ViewFeedback text_section text_question text_answer True)

            else
                onClick (Select text_answer)

        answer =
            TextReader.Answer.Model.answer text_answer

        answer_selected =
            TextReader.Answer.Model.selected text_answer

        is_correct =
            TextReader.Answer.Model.correct text_answer

        view_feedback =
            TextReader.Answer.Model.feedback_viewable text_answer
    in
    div
        [ classList <|
            [ ( "answer", True )
            , ( "answer-selected", answer_selected )
            ]
                ++ (if answer_selected || view_feedback then
                        if is_correct then
                            [ ( "correct", is_correct ) ]

                        else
                            [ ( "incorrect", not is_correct ) ]

                    else
                        []
                   )
        , on_click
        ]
        [ div [ classList [ ( "answer-text", True ), ( "bolder", answer_selected ) ] ] [ Html.text answer.text ]
        , if answer_selected || view_feedback then
            div [ class "answer-feedback" ] [ Html.em [] [ Html.text answer.feedback ] ]

          else
            Html.text ""
        ]


view_exceptions : SafeModel -> Html Msg
view_exceptions (SafeModel model) =
    div [ class "exception" ]
        (case model.exception of
            Just exception ->
                [ Html.text exception.error_msg
                ]

            Nothing ->
                []
        )


view_prev_btn : Html Msg
view_prev_btn =
    div [ onClick PrevSection, class "prev-btn" ]
        [ Html.text "Previous"
        ]


view_next_btn : Html Msg
view_next_btn =
    div [ onClick NextSection, class "next-btn" ]
        [ Html.text "Next"
        ]


view_text_complete : SafeModel -> TextScores -> Html Msg
view_text_complete (SafeModel model) scores =
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
        , view_text_conclusion model.text
        , div [ id "nav" ]
            [ view_prev_btn
            , div [ onClick StartOver ] [ Html.text "Start Over" ]
            ]
        ]


view_text_conclusion : Text -> Html Msg
view_text_conclusion text =
    div [ attribute "id" "text-conclusion" ]
        -- (HtmlParser.Util.toVirtualDom <| HtmlParser.parse (Maybe.withDefault "" text.conclusion))
        []


isPartOfCompoundWord : Section -> Int -> String -> Maybe ( Int, Int, Int )
isPartOfCompoundWord section instance word =
    case TextReader.Section.Model.getTextWord section instance word of
        Just text_word ->
            case TextReader.TextWord.group text_word of
                Just group ->
                    Just ( group.instance, group.pos, group.length )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


tagWord : SafeModel -> Section -> Int -> String -> Html Msg
tagWord (SafeModel model) text_reader_section instance token =
    let
        id =
            String.join "_" [ String.fromInt instance, token ]

        textreader_textword =
            TextReader.Section.Model.getTextWord text_reader_section instance token

        reader_word =
            TextReader.Model.new id instance token textreader_textword
    in
    -- case token == " " of
    --     True ->
    --         VirtualDom.text token
    --     False ->
    --         case textreader_textword of
    --             Just text_word ->
    --                 if TextReader.TextWord.hasTranslations text_word then
    --                     view_defined_word model reader_word text_word token
    --                 else
    --                     VirtualDom.text token
    --             Nothing ->
    --                 VirtualDom.text token
    Html.text ""



-- view_defined_word : Model -> TextReader.Model.TextReaderWord -> TextReader.TextWord.TextWord -> String -> Html Msg
-- view_defined_word model reader_word text_word token =
--     Html.node "span"
--         [ classList
--             [ ( "defined-word", True )
--             , ( "cursor", True )
--             ]
--         , onClick (ToggleGloss reader_word)
--         ]
--         [ span [ classList [ ( "highlighted", TextReader.Model.glossed reader_word model.gloss ) ] ]
--             [ VirtualDom.text token
--             ]
--         , view_gloss model reader_word text_word
--         ]
--
-- view_translation : TextReader.TextWord.Translation -> Html Msg
-- view_translation translation =
--     div [ class "translation" ] [ Html.text translation.text ]
--
-- view_translations : Maybe (List TextReader.TextWord.Translation) -> Html Msg
-- view_translations defs =
--     div [ class "translations" ]
--         (case defs of
--             Just translations ->
--                 List.map view_translation (List.filter (\tr -> tr.correct_for_context) translations)
--             Nothing ->
--                 []
--         )
--
-- view_word_and_grammemes : TextReaderWord -> TextReader.TextWord.TextWord -> Html Msg
-- view_word_and_grammemes reader_word text_word =
--     div []
--         [ Html.text <| TextReader.Model.phrase reader_word ++ " (" ++ TextReader.TextWord.grammemesToString text_word ++ ")"
--         ]
--
-- view_flashcard_words : Model -> Html Msg
-- view_flashcard_words model =
--     div []
--         (List.map (\( normal_form, text_word ) -> div [] [ Html.text normal_form ])
--             (Dict.toList <| Maybe.withDefault Dict.empty <| User.Profile.TextReader.Flashcards.flashcards model.flashcard)
--         )
--
-- view_flashcard_options : Model -> TextReaderWord -> Html Msg
-- view_flashcard_options model reader_word =
--     let
--         phrase =
--             TextReader.Model.phrase reader_word
--         flashcards =
--             Maybe.withDefault Dict.empty (User.Profile.TextReader.Flashcards.flashcards model.flashcard)
--         add =
--             div [ class "cursor", onClick (AddToFlashcards reader_word) ] [ Html.text "Add to Flashcards" ]
--         remove =
--             div [ class "cursor", onClick (RemoveFromFlashcards reader_word) ] [ Html.text "Remove from Flashcards" ]
--     in
--     div [ class "gloss-flashcard-options" ]
--         (if Dict.member phrase flashcards then
--             [ remove ]
--          else
--             [ add ]
--         )
--
-- view_gloss : Model -> TextReaderWord -> TextReader.TextWord.TextWord -> Html Msg
-- view_gloss model reader_word text_word =
--     span []
--         [ span
--             [ classList [ ( "gloss-overlay", True ), ( "gloss-menu", True ) ]
--             , onMouseLeave (UnGloss reader_word)
--             , classList [ ( "hidden", not (TextReader.Model.selected reader_word model.gloss) ) ]
--             ]
--             [ view_word_and_grammemes reader_word text_word
--             , view_translations (TextReader.TextWord.translations text_word)
--             , view_flashcard_options model reader_word
--             ]
--         ]
-- VIEW: HEADER


viewHeader : SafeModel -> Html Msg
viewHeader safeModel =
    Views.view_header
        (viewTopHeader safeModel)
        (viewLowerMenu safeModel)


viewTopHeader : SafeModel -> List (Html Msg)
viewTopHeader safeModel =
    [ div [ classList [ ( "menu_item", True ) ] ]
        [ a
            [ class "link"
            , href
                (Route.toString Route.Profile__Student)
            ]
            [ text "Profile" ]
        ]
    , div [ classList [ ( "menu_item", True ) ] ]
        [ a [ class "link", onClick Logout ]
            [ text "Logout" ]
        ]

    -- , div [] [ viewProfileHint safeModel ]
    ]


viewLowerMenu : SafeModel -> List (Html Msg)
viewLowerMenu (SafeModel model) =
    [ div
        [ classList
            [ ( "lower-menu-item", True )
            ]
        ]
        [ a
            [ class "link"
            , href (Route.toString Route.Text__Search)
            ]
            [ text "Find a text to read" ]
        ]
    , div
        [ classList [ ( "lower-menu-item", True ) ] ]
        [ a
            [ class "link"
            , href (Route.toString Route.NotFound)
            ]
            [ text "Practice Flashcards" ]
        ]
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
subscriptions _ =
    -- TextReader.WebSocket.listen
    Sub.none
