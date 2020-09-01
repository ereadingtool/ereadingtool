module Utils.Date exposing (monthDayYearFormat)

import DateTime
import Time


padZero : Int -> Int -> String
padZero zeros num =
    case String.toInt <| "1" ++ String.repeat (zeros - 1) "0" of
        Just places ->
            if num > places then
                String.fromInt num

            else
                String.repeat zeros "0" ++ String.fromInt num

        _ ->
            String.fromInt num


hourMinSecFmt : DateTime.DateTime -> String
hourMinSecFmt date =
    String.join " "
        [ String.join ":"
            [ padZero 1 (DateTime.getHours date)
            , padZero 1 (DateTime.getMinutes date)
            , padZero 1 (DateTime.getSeconds date)
            ]
        , amPMFormat date
        ]


amPMFormat : DateTime.DateTime -> String
amPMFormat date =
    if DateTime.getHours date < 12 then
        "AM"

    else
        "PM"



-- monthDayYearFormat : DateTime.DateTime -> String
-- monthDayYearFormat date =
--     List.foldr (++) "" <|
--         List.map (\s -> s ++ "  ")
--             [ String.fromInt <| Calendar.monthToInt <| DateTime.getMonth date
--             , (String.fromInt <| DateTime.getDay date) ++ ","
--             , hourMinSecFmt date
--             , String.fromInt <| DateTime.getYear date
--             ]


monthDayYearFormat : DateTime.DateTime -> String
monthDayYearFormat date =
    List.foldr (++) "" <|
        List.map (\s -> s ++ "  ")
            [ toMonthString <| DateTime.getMonth date
            , (String.fromInt <| DateTime.getDay date) ++ ","
            , hourMinSecFmt date
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
