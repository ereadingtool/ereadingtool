import Html exposing (..)
import Html.Attributes exposing (classList, attribute)

import Http exposing (..)
import Date exposing (..)

import Text.Model exposing (TextListItem)
import Text.Decode

import Config exposing (..)
import Flags

import Views
import Profile

-- UPDATE
type Msg = Update (Result Http.Error (List TextListItem))

type alias Flags = Flags.Flags {}

type alias Model = {
    texts : List TextListItem
  , profile : Profile.Profile
  , flags : Flags
  }

type alias Filter = List String

init : Flags -> (Model, Cmd Msg)
init flags = ({
      texts=[]
    , profile=Profile.init_profile flags
    , flags=flags
  }, updateTexts [])

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


updateTexts : Filter -> Cmd Msg
updateTexts filter =
  let
    request = Http.get text_api_endpoint Text.Decode.textListDecoder
  in
    Http.send Update request


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Update (Ok texts) ->
      ({ model | texts = texts }, Cmd.none)
    -- handle user-friendly msgs
    Update (Err err) -> let _ = Debug.log "error" err in
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


view_text : TextListItem -> Html Msg
view_text text_list_item =
   div [ classList[("text_item", True)] ] [
     div [classList [("item_property", True)], attribute "data-id" (toString text_list_item.id)] [ Html.text "" ]
   , div [classList [("item_property", True)]] [
       Html.a [attribute "href" ("/admin/text/" ++ (toString text_list_item.id))] [ Html.text text_list_item.title ]
     , span [classList [("sub_description", True)]] [
         Html.text <| "Modified:   " ++ (month_day_year_fmt text_list_item.modified_dt)
       ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text <| toString text_list_item.text_section_count
        , span [classList [("sub_description", True)]] [
             Html.text "Texts"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text "1"
        , span [classList [("sub_description", True)]] [
             Html.text "Languages"
           ]
     ]
   , div [classList [("item_property", True)]] [
        Html.text text_list_item.author
        , span [classList [("sub_description", True)]] [
             Html.text "Author"
           ]
     ]
   , view_tags text_list_item
   , div [classList [("item_property", True)]] [
        Html.text text_list_item.created_by
        , span [classList [("sub_description", True)]] [
             Html.text "Created By"
           ]
     ]
 ]

view_tags : TextListItem -> Html Msg
view_tags text_list_item =
  div [classList [("item_property", True)]] [
     span [attribute "class" "tag"] [
       Html.text
         (case text_list_item.tags of
           Just tags ->
             String.join ", " tags
           Nothing ->
             "")
     ]
   , span [classList [("sub_description", True)]] [
         Html.text "Tags"
     ]
 ]

view_texts : Model -> Html Msg
view_texts model =
  div [classList [("text_items", True)] ] (List.map view_text model.texts)

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
