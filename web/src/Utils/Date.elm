module Utils.Date exposing (monthDayYearFormat)

import DateTime
import Time


monthDayYearFormat : DateTime.DateTime -> String
monthDayYearFormat date =
    String.join " "
        [ toMonthString <| DateTime.getMonth date
        , (String.fromInt <| DateTime.getDay date) ++ ","
        , hourMinSecFormat date
        , String.fromInt <| DateTime.getYear date
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


hourMinSecFormat : DateTime.DateTime -> String
hourMinSecFormat date =
    String.join " "
        [ String.join ":"
            [ String.fromInt (toTwelveHourClock (DateTime.getHours date))
            , padZero (DateTime.getMinutes date)
            , padZero (DateTime.getSeconds date)
            ]
        , amPMFormat date
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


amPMFormat : DateTime.DateTime -> String
amPMFormat date =
    if DateTime.getHours date < 12 then
        "AM"

    else
        "PM"
