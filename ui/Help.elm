module Help exposing
    ( CurrentHelpMsgIndex
    , HelpMsgID
    , HelpMsgOverlayID
    , HelpMsgStr
    , HelpMsgVisible
    )

import Dict exposing (Dict)


type alias HelpMsgOverlayID =
    String


type alias HelpMsgID =
    String


type alias HelpMsgStr =
    String


type alias HelpMsgVisible =
    Bool


type alias CurrentHelpMsgIndex =
    Int
