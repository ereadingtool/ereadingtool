module User.Student.Profile.Help exposing
    ( StudentHelp
    , StudentProfileHelp
    , helpID
    , helpMsg
    , init
    , isVisible
    , my_performanceHelp
    , next
    , popupToOverlayID
    , preferredDifficultyHelp
    , prev
    , profileHelp
    , scrollToFirstMsg
    , scrollToNextMsg
    , scrollToPrevMsg
    , searchTextsHelp
    , setVisible
    , usernameHelp
    )

import Help exposing (HelpMsgID, HelpMsgOverlayID, HelpMsgStr, HelpMsgVisible)
import Help.PopUp exposing (Help)


type StudentHelp
    = UsernameHelp HelpMsgStr
    | MyPerformanceHelp HelpMsgStr
    | PreferredDifficultyHelp HelpMsgStr
    | UsernameMenuItemHelp HelpMsgStr
    | SearchTextsMenuItemHelp HelpMsgStr


type StudentProfileHelp
    = StudentProfileHelp (Help StudentHelp)


usernameHelp : StudentHelp
usernameHelp =
    UsernameHelp
        """You can create a new username that is distinct from your email address if you choose.
     Your username will be visible to instructors and other students if you comment on any texts."""


my_performanceHelp : StudentHelp
my_performanceHelp =
    MyPerformanceHelp
        """As you use the website, make sure to check back here from time to time.
     You will be able to see the percentage of questions that you have answered correctly over varying time periods
     and difficulties."""


preferredDifficultyHelp : StudentHelp
preferredDifficultyHelp =
    PreferredDifficultyHelp
        """Please choose a difficulty level. If you have taken proficiency tests, it would be advisable to start out
     reading texts at your current proficiency level.  If you’ve not taken a Flagship Proficiency test yet,
     then you can use these brief descriptions to pick the level that is closest to your current abilities."""


profileHelp : StudentHelp
profileHelp =
    UsernameMenuItemHelp
        """You can return to this profile page at any time, by clicking on your username in the top right corner of the
    screen. Hovering over your username, you can see the option to log out."""


searchTextsHelp : StudentHelp
searchTextsHelp =
    SearchTextsMenuItemHelp
        """To select a text to read, go to the Search Texts option that is in the menu bar on each page of the website."""


help_msgs : List StudentHelp
help_msgs =
    [ usernameHelp
    , my_performanceHelp
    , preferredDifficultyHelp
    , profileHelp
    , searchTextsHelp
    ]


init : StudentProfileHelp
init =
    StudentProfileHelp
        (Help.PopUp.init help_msgs popupToOverlayID popupToID)


help : StudentProfileHelp -> Help StudentHelp
help (StudentProfileHelp student_help) =
    student_help


helpID : StudentProfileHelp -> StudentHelp -> String
helpID student_help help_msg =
    Help.PopUp.helpID (help student_help) help_msg


setVisible : StudentProfileHelp -> StudentHelp -> HelpMsgVisible -> StudentProfileHelp
setVisible student_profile_help help_msg visible =
    StudentProfileHelp (Help.PopUp.setVisible (help student_profile_help) help_msg visible)


isVisible : StudentProfileHelp -> StudentHelp -> HelpMsgVisible
isVisible student_profile_help msg =
    Help.PopUp.isVisible (help student_profile_help) msg


scrollToNextMsg : StudentProfileHelp -> Cmd msg
scrollToNextMsg student_profile_help =
    Help.PopUp.scrollToNextMsg (help student_profile_help)


scrollToPrevMsg : StudentProfileHelp -> Cmd msg
scrollToPrevMsg student_profile_help =
    Help.PopUp.scrollToPrevMsg (help student_profile_help)


next : StudentProfileHelp -> StudentProfileHelp
next student_profile_help =
    StudentProfileHelp (Help.PopUp.next (help student_profile_help))


prev : StudentProfileHelp -> StudentProfileHelp
prev student_profile_help =
    StudentProfileHelp (Help.PopUp.prev (help student_profile_help))


scrollToFirstMsg : StudentProfileHelp -> Cmd msg
scrollToFirstMsg student_profile_help =
    Help.PopUp.scrollToFirstMsg (help student_profile_help)


helpMsg : StudentHelp -> HelpMsgStr
helpMsg help_msg =
    case help_msg of
        UsernameHelp unameHelp ->
            unameHelp

        MyPerformanceHelp performanceHelp ->
            performanceHelp

        PreferredDifficultyHelp difficultyHelp ->
            difficultyHelp

        UsernameMenuItemHelp unameItemHelp ->
            unameItemHelp

        SearchTextsMenuItemHelp textsItemHelp ->
            textsItemHelp


popupToID : StudentHelp -> HelpMsgID
popupToID studentHelp =
    case studentHelp of
        UsernameHelp _ ->
            "username_hint"

        MyPerformanceHelp _ ->
            "my_performance_hint"

        PreferredDifficultyHelp _ ->
            "preferred_difficulty_hint"

        UsernameMenuItemHelp _ ->
            "username_menu_item_hint"

        SearchTextsMenuItemHelp _ ->
            "search_text_menu_item_hint"


popupToOverlayID : StudentHelp -> HelpMsgOverlayID
popupToOverlayID help_popup =
    popupToID help_popup ++ "_overlay"
