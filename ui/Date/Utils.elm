module Date.Utils exposing (month_day_year_fmt)

import Calendar
import DateTime


pad_zero : Int -> Int -> String
pad_zero zeros num =
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
            [ pad_zero 1 (DateTime.getHours date - 12)
            , pad_zero 1 (DateTime.getMinutes date)
            , pad_zero 1 (DateTime.getSeconds date)
            ]
        , am_pm_fmt date
        ]


am_pm_fmt : DateTime.DateTime -> String
am_pm_fmt date =
    if DateTime.getHours date < 12 then
        "AM"

    else
        "PM"


month_day_year_fmt : DateTime.DateTime -> String
month_day_year_fmt date =
    List.foldr (++) "" <|
        List.map (\s -> s ++ "  ")
            [ String.fromInt <| Calendar.monthToInt <| DateTime.getMonth date
            , (String.fromInt <| DateTime.getDay date) ++ ","
            , hour_min_sec_fmt date
            , String.fromInt <| DateTime.getYear date
            ]
