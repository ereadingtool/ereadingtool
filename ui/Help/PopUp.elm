module Help.PopUp exposing (..)

import Array exposing (Array)
import Help exposing (CurrentHelpMsgIndex, HelpMsgID, HelpMsgOverlayID, HelpMsgStr, HelpMsgVisible)
import OrderedDict exposing (OrderedDict)
import Ports


type alias HelpMsgs help_msg =
    OrderedDict HelpMsgOverlayID ( help_msg, HelpMsgVisible )


type Help help_msg
    = Help (HelpMsgs help_msg) (help_msg -> HelpMsgOverlayID) (help_msg -> HelpMsgID) CurrentHelpMsgIndex


helpID : Help help_msg -> help_msg -> HelpMsgID
helpID (Help _ _ popup_to_id _) help_msg =
    popup_to_id help_msg


popupToOverlayID : Help help_msg -> help_msg -> HelpMsgOverlayID
popupToOverlayID (Help _ popup_to_overlay_id _ _) help_msg =
    popup_to_overlay_id help_msg


popupToID : Help help_msg -> help_msg -> HelpMsgID
popupToID (Help _ _ popup_to_id _) help_msg =
    popup_to_id help_msg


scrollToFirstMsg : Help help_msg -> Cmd msg
scrollToFirstMsg help =
    case getMsg help 0 of
        Just first_msg ->
            Ports.scrollTo (popupToID help first_msg)

        -- no first msg
        Nothing ->
            Cmd.none


scrollToNextMsg : Help help_msg -> Cmd msg
scrollToNextMsg help =
    case nextMsg help of
        Just ( next_msg, _ ) ->
            Ports.scrollTo (popupToID help next_msg)

        -- no messages
        Nothing ->
            Cmd.none


scrollToPrevMsg : Help help_msg -> Cmd msg
scrollToPrevMsg help =
    case prevMsg help of
        Just ( prev_msg, _ ) ->
            Ports.scrollTo (popupToID help prev_msg)

        -- no messages
        Nothing ->
            Cmd.none


toArray : HelpMsgs help_msg -> Array ( HelpMsgOverlayID, ( help_msg, HelpMsgVisible ) )
toArray help_msgs =
    Array.fromList <| OrderedDict.toList help_msgs


isVisible : Help help_msg -> help_msg -> HelpMsgVisible
isVisible help msg =
    case OrderedDict.get (popupToOverlayID help msg) (msgs help) of
        Just ( help_msg, help_msg_visible ) ->
            help_msg_visible

        Nothing ->
            False


setMsgs : Help help_msg -> HelpMsgs help_msg -> Help help_msg
setMsgs (Help _ msg_to_overlay_id msg_to_id current_index) new_msgs =
    Help new_msgs msg_to_overlay_id msg_to_id current_index


msgs : Help help_msg -> OrderedDict HelpMsgOverlayID ( help_msg, HelpMsgVisible )
msgs (Help help_msgs _ _ _) =
    help_msgs


currentMsgIndex : Help help_msg -> Int
currentMsgIndex (Help help_msg _ _ i) =
    i


currentMsg : Help help_msg -> Maybe help_msg
currentMsg help =
    let
        current_msg_index =
            currentMsgIndex help
    in
    getMsg help current_msg_index


nextMsg : Help help_msg -> Maybe ( help_msg, Int )
nextMsg help =
    let
        current_msg_index =
            currentMsgIndex help

        next_msg_index =
            current_msg_index + 1
    in
    case getMsg help current_msg_index of
        Just current_msg ->
            case getMsg help next_msg_index of
                Just next_msg ->
                    Just ( next_msg, next_msg_index )

                -- loop back
                Nothing ->
                    case getMsg help 0 of
                        Just first_msg ->
                            Just ( first_msg, 0 )

                        -- no first msg
                        Nothing ->
                            Nothing

        -- no current message
        Nothing ->
            Nothing


prevMsg : Help help_msg -> Maybe ( help_msg, Int )
prevMsg help =
    let
        current_msg_index =
            currentMsgIndex help

        prev_msg_index =
            current_msg_index - 1
    in
    case getMsg help current_msg_index of
        Just current_msg ->
            case getMsg help prev_msg_index of
                Just prev_msg ->
                    Just ( prev_msg, prev_msg_index )

                -- go to end
                Nothing ->
                    let
                        last_msg_index =
                            Array.length (msgs help |> toArray) - 1
                    in
                    case getMsg help last_msg_index of
                        Just last_msg ->
                            Just ( last_msg, last_msg_index )

                        -- no last index
                        Nothing ->
                            Nothing

        -- no current msg
        Nothing ->
            Nothing


getMsg : Help help_msg -> Int -> Maybe help_msg
getMsg help index =
    let
        ordered_msgs =
            toArray (msgs help)
    in
    case Array.get index ordered_msgs of
        Just ( _, ( msg, _ ) ) ->
            Just msg

        Nothing ->
            Nothing


setCurrentMsgIndex : Help help_msg -> Int -> Help help_msg
setCurrentMsgIndex (Help help_msg popup_to_overlay_id popup_to_id _) new_index =
    Help help_msg popup_to_overlay_id popup_to_id new_index


next : Help help_msg -> Help help_msg
next help =
    let
        current_msg_index =
            currentMsgIndex help
    in
    case nextMsg help of
        Just ( next_msg, next_msg_index ) ->
            setCurrentMsgIndex (setVisible help next_msg True) next_msg_index

        -- no messages
        Nothing ->
            help


prev : Help help_msg -> Help help_msg
prev help =
    let
        current_msg_index =
            currentMsgIndex help
    in
    case prevMsg help of
        Just ( prev_msg, prev_msg_index ) ->
            setCurrentMsgIndex (setVisible help prev_msg True) prev_msg_index

        -- no messages
        Nothing ->
            help


setAllInvisible : HelpMsgs help_msg -> HelpMsgs help_msg
setAllInvisible messages =
    OrderedDict.fromList <|
        List.map
            (\( id, ( help_msg, _ ) ) -> ( id, ( help_msg, False ) ))
            (OrderedDict.toList <| messages)


setVisible : Help help_msg -> help_msg -> HelpMsgVisible -> Help help_msg
setVisible help help_msg visible =
    let
        help_msg_id =
            popupToOverlayID help help_msg

        help_msgs =
            setAllInvisible (msgs help)

        new_msgs =
            OrderedDict.insert help_msg_id ( help_msg, visible ) help_msgs
    in
    setMsgs help new_msgs


init : List help_msg -> (help_msg -> HelpMsgOverlayID) -> (help_msg -> HelpMsgID) -> Help help_msg
init help_msgs popup_to_overlay_id popup_to_id =
    let
        initial_msgs =
            OrderedDict.fromList <|
                List.map (\help_msg -> ( popup_to_overlay_id help_msg, ( help_msg, False ) ))
                    help_msgs
    in
    case List.head help_msgs of
        Just first_msg ->
            setVisible (Help initial_msgs popup_to_overlay_id popup_to_id 0) first_msg True

        -- empty list of msgs
        Nothing ->
            Help initial_msgs popup_to_overlay_id popup_to_id 0
