module Tests.Date exposing (..)

import DateTime
import Expect
import Test exposing (..)
import Time
import Utils.Date exposing (monthDayYearFormat)


suite : Test
suite =
    describe "The Utils.Date module"
        [ test "Start of POSIX time" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 0)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Jan 1, 12:00:00 AM 1970"
        , test "High noon on longest day of 2020" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 1592654400000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Jun 20, 12:00:00 PM 2020"
        , test "A morning time with a single digit hour" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 1573546352000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Nov 12, 8:12:32 AM 2019"
        , test "An afternoon time with a single digit hour" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 1236007965000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Mar 2, 3:32:45 PM 2009"
        , test "A morning time with a double digit hour" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 990963165000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "May 27, 11:32:45 AM 2001"
        , test "A afternoon time with a double digit hour" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 1070319839000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Dec 1, 11:03:59 PM 2003"
        , test "Minutes and seconds are padded with zeros, but not hours" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 1373900582000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Jul 15, 3:03:02 PM 2013"
        , test "Leap day 2020" <|
            \_ ->
                let
                    startPosix =
                        DateTime.fromPosix (Time.millisToPosix 1582990200000)
                in
                monthDayYearFormat startPosix
                    |> Expect.equal "Feb 29, 3:30:00 PM 2020"
        ]
