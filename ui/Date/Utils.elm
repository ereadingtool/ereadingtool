module Date.Utils exposing (..)

import DateTime


pad_zero : Int -> Int -> String
pad_zero zeros num =
    case String.toInt <| "1" ++ String.repeat (zeros - 1) "0" of
        Ok places ->
            case num > places of
                True ->
                    toString num

                False ->
                    String.repeat zeros "0" ++ toString num

        _ ->
            toString num


hour_min_sec_fmt : DateTime.DateTime -> String
hour_min_sec_fmt date =
    String.join " "
        [ String.join ":" [ pad_zero 1 (DateTime.hour date - 12), pad_zero 1 (Date.minute date), pad_zero 1 (Date.second date) ]
        , am_pm_fmt date
        ]


am_pm_fmt : DateTime.DateTime -> String
am_pm_fmt date =
    case Date.hour date < 12 of
        True ->
            "AM"

        False ->
            "PM"


month_day_year_fmt : DateTime.DateTime -> String
month_day_year_fmt date =
    List.foldr (++) "" <|
        List.map (\s -> s ++ "  ")
            [ toString <| Date.month date, (toString <| Date.day date) ++ ",", hour_min_sec_fmt date, toString <| Date.year date ]
