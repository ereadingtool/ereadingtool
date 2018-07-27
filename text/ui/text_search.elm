import Html exposing (Html, div, span, datalist, option)
import Html.Attributes exposing (classList, class, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)

import Text.Model exposing (Text)
import Text.Decode

import Text.Search exposing (TextSearch)
import Text.Search.Option

import Text.Search.Tag exposing (TagSearch)
import Text.Search.Difficulty exposing (DifficultySearch)

import Text.Tags.View

import Ports exposing (clearInputText)

import Dict exposing (Dict)

import Views
import Profile

import Config exposing (..)
import Flags exposing (CSRFToken)

-- UPDATE
type Msg =
   AddDifficulty String Bool
 | SelectTag String
 | DeselectTag String
 | TextSearch (Result Http.Error (List Text.Model.TextListItem))

type alias Flags = Flags.Flags { text_difficulties: List Text.Model.TextDifficulty, text_tags: List String }

type alias Model = {
    results : List Text.Model.TextListItem
  , profile : Profile.Profile
  , text_search : TextSearch
  , flags : Flags }

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    tag_search =
      Text.Search.Tag.new "text_tag_search"
        (Text.Search.Option.new_options (List.map (\tag -> (tag, tag)) flags.text_tags))
    difficulty_search =
      Text.Search.Difficulty.new "text_difficulty_search" (Text.Search.Option.new_options flags.text_difficulties)
  in
    ({
      results=[]
    , profile=Profile.init_profile flags
    , text_search=Text.Search.new text_api_endpoint tag_search difficulty_search
    , flags=flags
    }
    , Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update_results : TextSearch -> Cmd Msg
update_results text_search =
  let
    filter_params = Text.Search.filter_params text_search
    query_string = String.join "" [text_api_endpoint, "?"] ++ (String.join "&" filter_params)
    request = Http.get query_string Text.Decode.textListDecoder
  in
    if (List.length filter_params) > 0 then
      Http.send TextSearch request
    else
      Cmd.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    AddDifficulty difficulty select ->
      let
        difficulty_search = Text.Search.difficulty_search model.text_search
        new_difficulty_search = Text.Search.Difficulty.select_difficulty difficulty_search difficulty select
        new_text_search = Text.Search.set_difficulty_search model.text_search new_difficulty_search
      in
        ({ model | text_search = new_text_search, results = [] }, update_results new_text_search)

    SelectTag tag_name ->
      let
        tag_search = Text.Search.tag_search model.text_search
        tag_search_input_id = Text.Search.Tag.input_id tag_search
        new_tag_search = Text.Search.Tag.select_tag tag_search tag_name True
        new_text_search = Text.Search.set_tag_search model.text_search new_tag_search
      in
        ({ model | text_search = new_text_search, results = [] }
        , Cmd.batch [clearInputText tag_search_input_id, update_results new_text_search])

    DeselectTag tag_name ->
      let
        tag_search = Text.Search.tag_search model.text_search
        new_tag_search = Text.Search.Tag.select_tag tag_search tag_name False
        new_text_search = Text.Search.set_tag_search model.text_search new_tag_search
      in
        ({ model | text_search = new_text_search, results = [] }, update_results new_text_search)

    TextSearch result ->
      case result of
        Ok texts ->
          ({ model | results = texts }, Cmd.none)
        Err err -> let _ = Debug.log "error retrieving results" err in
          (model, Cmd.none)

main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_tags : TagSearch -> Html Msg
view_tags tag_search =
  let
    tags = Text.Search.Tag.optionsToDict tag_search
    tag_search_id = Text.Search.Tag.input_id tag_search
    tag_list = Dict.keys tags
    selected_tags = Dict.filter (\k v -> Text.Search.Option.selected v) tags
  in
    Text.Tags.View.view_tags tag_search_id
      tag_list (Dict.map (\k v -> Text.Search.Option.label v) selected_tags) (onInput SelectTag, DeselectTag)

view_difficulties : DifficultySearch -> List (Html Msg)
view_difficulties difficulty_search =
  let
    difficulties = Text.Search.Difficulty.options difficulty_search
    view_difficulty (value, difficulty_search_option) =
      let
        selected = Text.Search.Option.selected difficulty_search_option
        label = Text.Search.Option.label difficulty_search_option
      in
        div [classList [("difficulty_option", True), ("difficulty_option_selected", selected)]
            , onClick (AddDifficulty value (not selected))] [
          Html.text label
        ]
  in
    List.map view_difficulty <| List.map (\option -> (Text.Search.Option.value option, option)) difficulties

view_search_filters : Model -> Html Msg
view_search_filters model =
  div [attribute "id" "text_search_filters"] [
    div [attribute "id" "text_search_filters_label"] [ Html.text "Filters" ]
  , div [class "search_filter"] [
      div [class "search_filter_title"] [ Html.text "Difficulty" ]
    , div [] (view_difficulties (Text.Search.difficulty_search model.text_search))
    ]
  , div [class "search_filter"] [
      div [class "search_filter_title"] [ Html.text "Tags" ]
    , div [] [view_tags (Text.Search.tag_search model.text_search)]
    ]
  ]

view_search_results : List Text.Model.TextListItem  -> Html Msg
view_search_results text_list_items =
  let
    view_search_result text_item =
      let
        tags =
          (case text_item.tags of
            Just tags -> String.join ", " tags
            Nothing -> "")
      in
        div [class "search_result"] [
          div [] [ Html.text text_item.title, div [class "sub_description"] [ Html.text "Title" ] ]
        , div [] [ Html.text text_item.difficulty, div [class "sub_description"] [ Html.text "Difficulty" ] ]
        , div [] [ Html.text tags, div [class "sub_description"] [ Html.text "Tags" ] ]
        , div [] [ Html.text (toString text_item.text_section_count)
                 , div [class "sub_description"] [ Html.text "Sections" ] ]
        , div [] [ Html.text "1 / 4 sections complete", div [class "sub_description"] [ Html.text "progress" ] ]
        ]
  in
    div [attribute "id" "text_search_results"] (List.map view_search_result text_list_items)

view_search_footer : Model -> Html Msg
view_search_footer model =
  div [attribute "id" "footer_items"] [
    div [attribute "id" "footer", class "message"] [
        Html.text <| "Showing " ++ toString (List.length model.results) ++ " entries"
    ]
  ]

view_content : Model -> Html Msg
view_content model =
  div [attribute "id" "text_search"] [
    view_search_filters model
  , view_search_results model.results
  , view_search_footer model
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header model.profile Nothing)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
