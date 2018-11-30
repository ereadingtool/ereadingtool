module Student.Profile.Help exposing (..)

import Help exposing (HelpMsgID, HelpMsgStr, HelpMsgVisible, CurrentHelpMsgIndex)

import Help.PopUp exposing (Help)

type StudentHelp =
    UsernameHelp HelpMsgStr
  | MyPerformanceHelp HelpMsgStr
  | PreferredDifficultyHelp HelpMsgStr
  | UsernameMenuItemHelp HelpMsgStr
  | SearchTextsMenuItemHelp HelpMsgStr

type StudentProfileHelp = StudentProfileHelp (Help StudentHelp)


username_help : StudentHelp
username_help =
  UsernameHelp
     """You can create a new username that is distinct from your email address if you choose.
     Your username will be visible to instructors and other students if you comment on any texts."""

my_performance_help : StudentHelp
my_performance_help =
  MyPerformanceHelp
     """As you use the website, make sure to check back here from time to time.
     You will be able to see the percentage of questions that you have answered correctly over varying time periods
     and difficulties."""

preferred_difficulty_help : StudentHelp
preferred_difficulty_help =
  PreferredDifficultyHelp
     """Please choose a difficulty level. If you have taken proficiency tests, it would be advisable to start out
     reading texts at your current proficiency level.  If you’ve not taken a Flagship Proficiency test yet,
     then you can use these brief descriptions to pick the level that is closest to your current abilities."""

username_menu_item_help : StudentHelp
username_menu_item_help =
  UsernameMenuItemHelp
    """You can return to this profile page at any time, by clicking on your username in the top right corner of the
    screen. Hovering over your username, you can see the option to log out."""

search_menu_item_help : StudentHelp
search_menu_item_help =
  SearchTextsMenuItemHelp
    """To select a text to read, go to the Search Texts option that is in the menu bar on each page of the website."""

help_msgs : List StudentHelp
help_msgs = [
   username_help
 , my_performance_help
 , preferred_difficulty_help
 , username_menu_item_help
 , search_menu_item_help
 ]

init : StudentProfileHelp
init =
  StudentProfileHelp (Help.PopUp.init help_msgs popupToID)

help : StudentProfileHelp -> Help StudentHelp
help (StudentProfileHelp student_help) =
  student_help

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
    UsernameHelp help ->
      help

    MyPerformanceHelp help ->
      help

    PreferredDifficultyHelp help ->
      help

    UsernameMenuItemHelp help ->
      help

    SearchTextsMenuItemHelp help ->
      help

popupToID : StudentHelp -> HelpMsgID
popupToID help_popup =
  case help_popup of
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
