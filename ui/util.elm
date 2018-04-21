module Util exposing (is_valid_email)

import Regex

valid_email_regex : Regex.Regex
valid_email_regex = Regex.regex "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+.[a-zA-Z0-9-.]+$" |> Regex.caseInsensitive

is_valid_email : String -> Bool
is_valid_email addr = Regex.contains valid_email_regex addr