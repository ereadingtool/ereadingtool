module Student.Profile.Help exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)

import HelpMsg exposing (HelpMsgID, HelpMsgStr, HelpMsgVisible)


type HelpMsg =
    UsernameHelp HelpMsgStr
  | MyPerformanceHelp HelpMsgStr
  | PreferredDifficultyHelp HelpMsgStr
  | UsernameMenuItemHelp HelpMsgStr
  | SearchTextsMenuItemHelp HelpMsgStr

type StudentProfileHelp = StudentProfileHelp (Dict HelpMsgID (HelpMsg, HelpMsgVisible))

username_help : HelpMsg
username_help =
  UsernameHelp
     """You can create a new username that is distinct from your email address if you choose.
     Your username will be visible to instructors and other students if you comment on any texts."""

my_performance_help : HelpMsg
my_performance_help =
  MyPerformanceHelp
     """As you use the website, make sure to check back here from time to time.
     You will be able to see the percentage of questions that you have answered correctly over varying time periods
     and difficulties."""

preferred_difficulty_help : HelpMsg
preferred_difficulty_help =
  PreferredDifficultyHelp
     """Please choose a difficulty level. If you have taken proficiency tests, it would be advisable to start out
     reading texts at your current proficiency level.  If you’ve not taken a Flagship Proficiency test yet,
     then you can use these brief descriptions to pick the level that is closest to your current abilities."""

username_menu_item_help : HelpMsg
username_menu_item_help =
  UsernameMenuItemHelp
    """You can return to this profile page at any time, by clicking on your username in the top right corner of the
    screen. Hovering over your username, you can see the option to log out."""

search_menu_item_help : HelpMsg
search_menu_item_help =
  SearchTextsMenuItemHelp
    """To select a text to read, go to the Search Texts option that is in the menu bar on each page of the website."""

help_msgs : List HelpMsg
help_msgs = [
   username_help
 , my_performance_help
 , preferred_difficulty_help
 , username_menu_item_help
 , search_menu_item_help
 ]

is_visible : StudentProfileHelp -> HelpMsg -> HelpMsgVisible
is_visible student_profile_help msg =
  case Dict.get (msgToId msg) (msgs student_profile_help) of
    Just (help_msg, help_msg_visible) ->
      help_msg_visible

    Nothing ->
      False

helpMsg : HelpMsg -> HelpMsgStr
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


msgToId : HelpMsg -> HelpMsgID
msgToId help_msg =
  case help_msg of
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


msgs : StudentProfileHelp -> Dict HelpMsgID (HelpMsg, HelpMsgVisible)
msgs (StudentProfileHelp help_msgs) =
  help_msgs


set_visible : HelpMsg -> HelpMsgVisible -> StudentProfileHelp -> StudentProfileHelp
set_visible help_msg visible student_profile_help =
  let
    help_msg_id = msgToId help_msg
    new_msgs = Dict.insert help_msg_id (help_msg, visible) (msgs student_profile_help)
  in
    StudentProfileHelp new_msgs


init : StudentProfileHelp
init =
  let
    initial_msgs = Dict.fromList <| List.map (\help_msg -> (msgToId help_msg, (help_msg, False))) help_msgs
    profile_help = set_visible username_help True (StudentProfileHelp initial_msgs)
  in
    StudentProfileHelp initial_msgs
