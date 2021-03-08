module Tests.Date exposing (..)

import Expect
import Json.Encode.Extra exposing (posix)
import Test exposing (..)
import Time
import TimeZone exposing (america__los_angeles, asia__tokyo)
import Utils.Date exposing (monthDayYearFormat)


suite : Test
suite =
    describe "The Utils.Date module"
        [ test "Start of POSIX time" <|
            \_ ->
                let
                    startPosix =
                        Time.millisToPosix 0
                in
                monthDayYearFormat Time.utc startPosix
                    |> Expect.equal "Jan 1, 12:00:00 AM 1970"
        , test "High noon on longest day of 2020" <|
            \_ ->
                let
                    highNoon =
                        Time.millisToPosix 1592654400000
                in
                monthDayYearFormat Time.utc highNoon
                    |> Expect.equal "Jun 20, 12:00:00 PM 2020"
        , test "A morning time with a single digit hour" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 1573546352000
                in
                monthDayYearFormat Time.utc posixTime
                    |> Expect.equal "Nov 12, 8:12:32 AM 2019"
        , test "An afternoon time with a single digit hour" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 1236007965000
                in
                monthDayYearFormat Time.utc posixTime
                    |> Expect.equal "Mar 2, 3:32:45 PM 2009"
        , test "A morning time with a double digit hour" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 990963165000
                in
                monthDayYearFormat Time.utc posixTime
                    |> Expect.equal "May 27, 11:32:45 AM 2001"
        , test "A afternoon time with a double digit hour" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 1070319839000
                in
                monthDayYearFormat Time.utc posixTime
                    |> Expect.equal "Dec 1, 11:03:59 PM 2003"
        , test "Minutes and seconds are padded with zeros, but not hours" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 1373900582000
                in
                monthDayYearFormat Time.utc posixTime
                    |> Expect.equal "Jul 15, 3:03:02 PM 2013"
        , test "Leap day 2020" <|
            \_ ->
                let
                    leapDay =
                        Time.millisToPosix 1582990200000
                in
                monthDayYearFormat Time.utc leapDay
                    |> Expect.equal "Feb 29, 3:30:00 PM 2020"
        , test "2020 Happy new year in Oregon" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 946713600000
                in
                monthDayYearFormat (america__los_angeles ()) posixTime
                    |> Expect.equal "Jan 1, 12:00:00 AM 2000"
        , test "Start of POSIX time in Oregon" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 0
                in
                monthDayYearFormat (america__los_angeles ()) posixTime
                    |> Expect.equal "Dec 31, 4:00:00 PM 1969"
        , test "Start of POSIX time in Tokyo" <|
            \_ ->
                let
                    posixTime =
                        Time.millisToPosix 0
                in
                monthDayYearFormat (asia__tokyo ()) posixTime
                    |> Expect.equal "Jan 1, 9:00:00 AM 1970"
        ]
