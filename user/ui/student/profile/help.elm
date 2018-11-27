module Student.Profile.Help exposing (..)

import Array exposing (Array)
import OrderedDict exposing (OrderedDict)

import HelpMsg exposing (HelpMsgID, HelpMsgStr, HelpMsgVisible, CurrentHelpMsgIndex)


type HelpMsg =
    UsernameHelp HelpMsgStr
  | MyPerformanceHelp HelpMsgStr
  | PreferredDifficultyHelp HelpMsgStr
  | UsernameMenuItemHelp HelpMsgStr
  | SearchTextsMenuItemHelp HelpMsgStr

type alias HelpMsgs = OrderedDict HelpMsgID (HelpMsg, HelpMsgVisible)

type StudentProfileHelp = StudentProfileHelp HelpMsgs CurrentHelpMsgIndex

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

toArray : HelpMsgs -> Array (HelpMsgID, (HelpMsg, HelpMsgVisible))
toArray help_msgs =
  Array.fromList <| OrderedDict.toList help_msgs

is_visible : StudentProfileHelp -> HelpMsg -> HelpMsgVisible
is_visible student_profile_help msg =
  case OrderedDict.get (msgToId msg) (msgs student_profile_help) of
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


msgs : StudentProfileHelp -> OrderedDict HelpMsgID (HelpMsg, HelpMsgVisible)
msgs (StudentProfileHelp help_msgs _) =
  help_msgs

currentMsgIndex : StudentProfileHelp -> Int
currentMsgIndex (StudentProfileHelp _ i) = i


getMsg : StudentProfileHelp -> Int -> Maybe HelpMsg
getMsg student_profile_help index =
  let
    ordered_msgs = toArray (msgs student_profile_help)
  in
    case Array.get index ordered_msgs of
      Just (_, (msg, _)) ->
        Just msg

      Nothing ->
        Nothing


setCurrentMsgIndex : StudentProfileHelp -> Int -> StudentProfileHelp
setCurrentMsgIndex (StudentProfileHelp msgs _) new_index =
  StudentProfileHelp msgs new_index

next : StudentProfileHelp -> StudentProfileHelp
next student_profile_help =
  let
    current_msg_index = currentMsgIndex student_profile_help
  in
    case getMsg student_profile_help current_msg_index of
      Just current_msg ->
        case getMsg student_profile_help (current_msg_index+1) of
          Just next_msg ->
            setCurrentMsgIndex (setVisible student_profile_help next_msg True) (current_msg_index+1)

          -- loop back
          Nothing ->
            setCurrentMsgIndex student_profile_help 0

      -- no current msg
      Nothing ->
        student_profile_help


prev : StudentProfileHelp -> StudentProfileHelp
prev student_profile_help =
  let
    current_msg_index = currentMsgIndex student_profile_help
  in
    case getMsg student_profile_help current_msg_index of
      Just current_msg ->
        case getMsg student_profile_help (current_msg_index-1) of
          Just prev_msg ->
            setCurrentMsgIndex (setVisible student_profile_help prev_msg True) (current_msg_index-1)

          -- go to end
          Nothing ->
            let
              last_msg_index = (Array.length (msgs student_profile_help |> toArray)) - 1
            in
              case getMsg student_profile_help last_msg_index of
                Just last_msg ->
                  setCurrentMsgIndex (setVisible student_profile_help last_msg True) last_msg_index

                -- no last index
                Nothing ->
                  student_profile_help

      -- no current msg
      Nothing ->
        student_profile_help

setAllInvisible : HelpMsgs -> HelpMsgs
setAllInvisible msgs =
  OrderedDict.fromList <| List.map
  (\(id, (help_msg, _)) -> (id, (help_msg, False)))
  (OrderedDict.toList <| msgs)


setVisible : StudentProfileHelp -> HelpMsg -> HelpMsgVisible -> StudentProfileHelp
setVisible student_profile_help help_msg visible =
  let
    help_msg_id = msgToId help_msg
    help_msgs = setAllInvisible (msgs student_profile_help)
    new_msgs = OrderedDict.insert help_msg_id (help_msg, visible) help_msgs
    current_msg_index = currentMsgIndex student_profile_help
  in
    StudentProfileHelp new_msgs current_msg_index


init : StudentProfileHelp
init =
  let
    initial_msgs = OrderedDict.fromList <| List.map (\help_msg -> (msgToId help_msg, (help_msg, False))) help_msgs
  in
    case List.head help_msgs of
      Just first_msg ->
        setVisible (StudentProfileHelp initial_msgs 0) first_msg True

      -- empty list of msgs
      Nothing ->
        (StudentProfileHelp initial_msgs 0)
