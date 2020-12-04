module Utils.Date exposing (monthDayYearFormat)

import Time
import Time.Extra


monthDayYearFormat : Time.Zone -> Time.Posix -> String
monthDayYearFormat zone posixTime =
    let
        parts =
            Time.Extra.posixToParts zone posixTime
    in
    String.join " "
        [ toMonthString <| parts.month
        , (String.fromInt <| parts.day) ++ ","
        , hourMinSecFormat parts
        , String.fromInt <| parts.year
        ]


toMonthString : Time.Month -> String
toMonthString month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


hourMinSecFormat : Time.Extra.Parts -> String
hourMinSecFormat parts =
    String.join " "
        [ String.join ":"
            [ String.fromInt (toTwelveHourClock parts.hour)
            , padZero parts.minute
            , padZero parts.second
            ]
        , amPMFormat parts.hour
        ]


padZero : Int -> String
padZero num =
    if num < 10 then
        "0" ++ String.fromInt num

    else
        String.fromInt num


toTwelveHourClock : Int -> Int
toTwelveHourClock hour =
    modBy 12 (hour + 11) + 1


amPMFormat : Int -> String
amPMFormat hour =
    if hour < 12 then
        "AM"

    else
        "PM"
