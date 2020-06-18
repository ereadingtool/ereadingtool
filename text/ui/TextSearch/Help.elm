module TextSearch.Help exposing (..)

import Help exposing (CurrentHelpMsgIndex, HelpMsgID, HelpMsgOverlayID, HelpMsgStr, HelpMsgVisible)
import Help.PopUp exposing (Help)


type TextHelp
    = DifficultyFilterHelp HelpMsgStr
    | TopicFilterHelp HelpMsgStr
    | StatusFilterHelp HelpMsgStr


type TextSearchHelp
    = TextSearchHelp (Help TextHelp)


difficulty_filter_help : TextHelp
difficulty_filter_help =
    DifficultyFilterHelp
        """The preferred difficulty that you selected on your User page is pre-selected here.
     You can choose additional difficulty levels or deselect difficulty levels as you please."""


topic_filter_help : TextHelp
topic_filter_help =
    TopicFilterHelp
        """Click on topics that interest you from this list of tags in order to see a list of texts that deal with these
     topics."""


status_filter_help : TextHelp
status_filter_help =
    StatusFilterHelp
        """As you use this site, texts will be sorted into three categories: Unread (ones that you’ve not yet read),
     In Progress (those that you started but haven’t finished), and Previously Read (ones that you’ve read before).
     You can access and (re)read any of these texts at any time."""


helpMsg : TextHelp -> HelpMsgStr
helpMsg help_msg =
    case help_msg of
        DifficultyFilterHelp help ->
            help

        TopicFilterHelp help ->
            help

        StatusFilterHelp help ->
            help


popupToOverlayID : TextHelp -> HelpMsgOverlayID
popupToOverlayID help_popup =
    popupToID help_popup ++ "_overlay"


popupToID : TextHelp -> HelpMsgID
popupToID help_popup =
    case help_popup of
        DifficultyFilterHelp _ ->
            "difficulty_filter_hint"

        TopicFilterHelp _ ->
            "topic_filter_hint"

        StatusFilterHelp _ ->
            "status_filter_hint"


help_msgs : List TextHelp
help_msgs =
    [ difficulty_filter_help
    , topic_filter_help
    , status_filter_help
    ]


init : TextSearchHelp
init =
    TextSearchHelp (Help.PopUp.init help_msgs popupToOverlayID popupToID)


help : TextSearchHelp -> Help TextHelp
help (TextSearchHelp student_help) =
    student_help


setVisible : TextSearchHelp -> TextHelp -> HelpMsgVisible -> TextSearchHelp
setVisible student_profile_help help_msg visible =
    TextSearchHelp (Help.PopUp.setVisible (help student_profile_help) help_msg visible)


isVisible : TextSearchHelp -> TextHelp -> HelpMsgVisible
isVisible student_profile_help msg =
    Help.PopUp.isVisible (help student_profile_help) msg


scrollToNextMsg : TextSearchHelp -> Cmd msg
scrollToNextMsg student_profile_help =
    Help.PopUp.scrollToNextMsg (help student_profile_help)


scrollToPrevMsg : TextSearchHelp -> Cmd msg
scrollToPrevMsg student_profile_help =
    Help.PopUp.scrollToPrevMsg (help student_profile_help)


next : TextSearchHelp -> TextSearchHelp
next student_profile_help =
    TextSearchHelp (Help.PopUp.next (help student_profile_help))


prev : TextSearchHelp -> TextSearchHelp
prev student_profile_help =
    TextSearchHelp (Help.PopUp.prev (help student_profile_help))


scrollToFirstMsg : TextSearchHelp -> Cmd msg
scrollToFirstMsg student_profile_help =
    Help.PopUp.scrollToFirstMsg (help student_profile_help)
