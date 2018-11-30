module Student.Profile.Help exposing (..)

import Array exposing (Array)
import OrderedDict exposing (OrderedDict)

import Ports

import Help exposing (HelpMsgID, HelpMsgStr, HelpMsgVisible, CurrentHelpMsgIndex)

import Help.PopUp exposing (Help)

type StudentHelp =
    UsernameHelp HelpMsgStr
  | MyPerformanceHelp HelpMsgStr
  | PreferredDifficultyHelp HelpMsgStr
  | UsernameMenuItemHelp HelpMsgStr
  | SearchTextsMenuItemHelp HelpMsgStr

-- type alias HelpMsgs help_popup = OrderedDict HelpMsgID (help_popup, HelpMsgVisible)
-- type alias HelpMsgs = OrderedDict HelpMsgID (StudentHelp, HelpMsgVisible)

-- type Help help_popup = Help (HelpMsgs help_popup) CurrentHelpMsgIndex
-- type StudentProfileHelp = StudentProfileHelp HelpMsgs CurrentHelpMsgIndex
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

{-scrollToFirstMsg : StudentProfileHelp -> Cmd msg
scrollToFirstMsg student_profile_help =
  case getMsg student_profile_help 0 of
    Just first_msg ->
      Ports.scrollTo (popupToID first_msg)

    -- no first msg
    Nothing ->
      Cmd.none

scrollToNextMsg : StudentProfileHelp -> Cmd msg
scrollToNextMsg student_profile_help =
  case nextMsg student_profile_help of
    Just next_msg ->
      Ports.scrollTo (popupToID next_msg)

    -- no messages
    Nothing ->
      Cmd.none

scrollToPrevMsg : StudentProfileHelp -> Cmd msg
scrollToPrevMsg student_profile_help =
  case prevMsg student_profile_help of
    Just prev_msg ->
      Ports.scrollTo (popupToID prev_msg)

    -- no messages
    Nothing ->
      Cmd.none

toArray : HelpMsgs -> Array (HelpMsgID, (StudentHelp, HelpMsgVisible))
toArray help_msgs =
  Array.fromList <| OrderedDict.toList help_msgs

isVisible : StudentProfileHelp -> StudentHelp -> HelpMsgVisible
isVisible student_profile_help msg =
  case OrderedDict.get (popupToID msg) (msgs student_profile_help) of
    Just (help_msg, help_msg_visible) ->
      help_msg_visible

    Nothing ->
      False-}

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


{-msgs : StudentProfileHelp -> OrderedDict HelpMsgID (StudentHelp, HelpMsgVisible)
msgs (StudentProfileHelp help_msgs _) =
  help_msgs

currentMsgIndex : StudentProfileHelp -> Int
currentMsgIndex (StudentProfileHelp _ i) = i


currentMsg : StudentProfileHelp -> Maybe StudentHelp
currentMsg student_profile_help =
  let
    current_msg_index = currentMsgIndex student_profile_help
  in
    getMsg student_profile_help current_msg_index


nextMsg : StudentProfileHelp -> Maybe StudentHelp
nextMsg student_profile_help =
  let
    current_msg_index = currentMsgIndex student_profile_help
  in
    case getMsg student_profile_help current_msg_index of
      Just current_msg ->
        case getMsg student_profile_help (current_msg_index+1) of
          Just next_msg ->
            Just next_msg

          -- loop back
          Nothing ->
            case getMsg student_profile_help 0 of
              Just first_msg ->
                Just first_msg

              -- no first msg
              Nothing ->
                Nothing

      -- no current message
      Nothing ->
         Nothing

prevMsg : StudentProfileHelp -> Maybe StudentHelp
prevMsg student_profile_help =
  let
    current_msg_index = currentMsgIndex student_profile_help
  in
    case getMsg student_profile_help current_msg_index of
      Just current_msg ->
        case getMsg student_profile_help (current_msg_index-1) of
          Just prev_msg ->
            Just prev_msg

          -- go to end
          Nothing ->
            let
              last_msg_index = (Array.length (msgs student_profile_help |> toArray)) - 1
            in
              case getMsg student_profile_help last_msg_index of
                Just last_msg ->
                  Just last_msg

                -- no last index
                Nothing ->
                  Nothing

      -- no current msg
      Nothing ->
        Nothing

getMsg : StudentProfileHelp -> Int -> Maybe StudentHelp
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
    next_msg_index = current_msg_index + 1
  in
    case nextMsg student_profile_help of
      Just next_msg ->
        setCurrentMsgIndex (setVisible student_profile_help next_msg True) next_msg_index

      -- no messages
      Nothing ->
        student_profile_help


prev : StudentProfileHelp -> StudentProfileHelp
prev student_profile_help =
  let
    current_msg_index = currentMsgIndex student_profile_help
    prev_msg_index = current_msg_index - 1
  in
    case prevMsg student_profile_help of
      Just prev_msg ->
        setCurrentMsgIndex (setVisible student_profile_help prev_msg True) prev_msg_index

      -- no messages
      Nothing ->
        student_profile_help


setAllInvisible : HelpMsgs -> HelpMsgs
setAllInvisible msgs =
  OrderedDict.fromList <| List.map
  (\(id, (help_msg, _)) -> (id, (help_msg, False)))
  (OrderedDict.toList <| msgs)


init : StudentProfileHelp
init =
  let
    initial_msgs = OrderedDict.fromList <| List.map (\help_msg -> (popupToID help_msg, (help_msg, False))) help_msgs
  in
    case List.head help_msgs of
      Just first_msg ->
        setVisible (StudentProfileHelp initial_msgs 0) first_msg True

      -- empty list of msgs
      Nothing ->
        (StudentProfileHelp initial_msgs 0)-}
