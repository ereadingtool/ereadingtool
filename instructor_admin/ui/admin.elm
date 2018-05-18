import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http exposing (..)
import Date exposing (..)

import Text.Model exposing (Text)
import Text.Decode
import Config exposing (..)
import Flags exposing (Flags)

import Views
import Profile

-- UPDATE
type Msg = Update (Result Http.Error (List Text))

type alias Model = {
    texts : List Text
  , profile : Profile.Profile
  , flags : Flags
  }

type alias Filter = List String

init : Flags -> (Model, Cmd Msg)
init flags = ({ texts=[], profile=Profile.init_profile flags, flags=flags }, updateTexts [])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


updateTexts : Filter -> Cmd Msg
updateTexts filter = let request = Http.get text_api_endpoint Text.Decode.textsDecoder in
  Http.send Update request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update (Ok texts) ->
      ({ model | texts = texts }, Cmd.none)
    -- handle user-friendly msgs
    Update (Err _) ->
      (model, Cmd.none)


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }


month_day_year_fmt : Date -> String
month_day_year_fmt date = List.foldr (++) "" <| List.map (\s -> s ++ "  ")
    [toString <| Date.month date, (toString <| Date.day date) ++ ",", toString <| Date.year date]


view_text : Text -> Html Msg
view_text text = let
   text_id = (case text.id of
     Just id -> toString id
     _ -> "") in
   div [ classList[("text_item", True)] ] [
     div [classList [("item_property", True)], attribute "data-id" (text_id)] [ Html.text "" ]
   , div [classList [("item_property", True)]] [
       Html.a [attribute "href" ("/quiz/" ++ text_id)] [ Html.text text.title ]
     , span [classList [("sub_description", True)]] [
         Html.text <| "Modified:   " ++ (case text.modified_dt of
           Just date -> month_day_year_fmt date
           _ -> "")
       ]
     ]
   , div [classList [("item_property", True)]] [
       Html.text text.difficulty
       , span [classList [("sub_description", True)]] [
             Html.text "Difficulty"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text <| toString text.question_count
        , span [classList [("sub_description", True)]] [
             Html.text "Questions"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text "1"
        , span [classList [("sub_description", True)]] [
             Html.text "Languages"
           ]
     ]   , div [classList [("action_menu", True)]] [ Html.text "" ]
 ]

view_texts : Model -> Html Msg
view_texts model = div [classList [("text_items", True)] ]
   (List.map view_text model.texts)

view_footer : Model -> Html Msg
view_footer model = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text <| "Showing " ++ toString (List.length model.texts) ++ " entries"
    ]
 ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    Views.view_header model.profile Nothing
  , Views.view_filter
  , (view_texts model)
  , (view_footer model)
  ]
