module Utils.Date exposing (monthDayYearFormat)

import Calendar
import DateTime


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


hour_min_sec_fmt : DateTime.DateTime -> String
hour_min_sec_fmt date =
    String.join " "
        [ String.join ":"
            [ padZero 1 (DateTime.getHours date - 12)
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


monthDayYearFormat : DateTime.DateTime -> String
monthDayYearFormat date =
    List.foldr (++) "" <|
        List.map (\s -> s ++ "  ")
            [ String.fromInt <| Calendar.monthToInt <| DateTime.getMonth date
            , (String.fromInt <| DateTime.getDay date) ++ ","
            , hour_min_sec_fmt date
            , String.fromInt <| DateTime.getYear date
            ]
