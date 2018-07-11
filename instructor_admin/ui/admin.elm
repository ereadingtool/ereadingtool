import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http exposing (..)
import Date exposing (..)

import Quiz.Model exposing (QuizListItem)
import Quiz.Decode

import Config exposing (..)
import Flags

import Views
import Profile

-- UPDATE
type Msg = Update (Result Http.Error (List QuizListItem))

type alias Flags = Flags.Flags {}

type alias Model = {
    quizzes : List QuizListItem
  , profile : Profile.Profile
  , flags : Flags
  }

type alias Filter = List String

init : Flags -> (Model, Cmd Msg)
init flags = ({
      quizzes=[]
    , profile=Profile.init_profile flags
    , flags=flags
  }, updateQuizzes [])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


updateQuizzes : Filter -> Cmd Msg
updateQuizzes filter =
  let
    request = Http.get quiz_api_endpoint Quiz.Decode.quizListDecoder
  in
    Http.send Update request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update (Ok quizzes) ->
      ({ model | quizzes = quizzes }, Cmd.none)
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


view_quiz : QuizListItem -> Html Msg
view_quiz quiz_list_item =
   div [ classList[("quiz_item", True)] ] [
     div [classList [("item_property", True)], attribute "data-id" (toString quiz_list_item.id)] [ Html.text "" ]
   , div [classList [("item_property", True)]] [
       Html.a [attribute "href" ("/admin/quiz/" ++ (toString quiz_list_item.id))] [ Html.text quiz_list_item.title ]
     , span [classList [("sub_description", True)]] [
         Html.text <| "Modified:   " ++ (month_day_year_fmt quiz_list_item.modified_dt)
       ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text <| toString quiz_list_item.text_count
        , span [classList [("sub_description", True)]] [
             Html.text "Texts"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text "1"
        , span [classList [("sub_description", True)]] [
             Html.text "Languages"
           ]
     ]   , div [classList [("action_menu", True)]] [ Html.text "" ]
 ]

view_quizzes : Model -> Html Msg
view_quizzes model =
  div [classList [("text_items", True)] ] (List.map view_quiz model.quizzes)

view_footer : Model -> Html Msg
view_footer model = div [classList [("footer_items", True)] ] [
    div [classList [("footer", True), ("message", True)] ] [
        Html.text <| "Showing " ++ toString (List.length model.quizzes) ++ " entries"
    ]
 ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    Views.view_header model.profile Nothing
  , Views.view_filter
  , (view_quizzes model)
  , (view_footer model)
  ]
