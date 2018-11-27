import Html exposing (Html, div, span, option)
import Html.Attributes exposing (classList, class, attribute, id)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)

import Text.Model exposing (Text)
import Text.Decode

import Text.Search exposing (TextSearch)
import Text.Search.Option

import Text.Search.Tag exposing (TagSearch)
import Text.Search.Difficulty exposing (DifficultySearch)

import Ports exposing (clearInputText)

import Dict exposing (Dict)

import Views

import Student.Profile
import User.Profile

import Config exposing (..)

import Profile.Flags as Flags

import Menu.Msg as MenuMsg
import Menu.Logout


-- UPDATE
type Msg =
   AddDifficulty String Bool
 | SelectTag String Bool
 | TextSearch (Result Http.Error (List Text.Model.TextListItem))
 | LogOut MenuMsg.Msg
 | LoggedOut (Result Http.Error Menu.Logout.LogOutResp)

type alias Flags = Flags.Flags { text_difficulties: List Text.Model.TextDifficulty, text_tags: List String }

type alias Model = {
    results : List Text.Model.TextListItem
  , profile : User.Profile.Profile
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

    profile=User.Profile.init_profile flags

    default_search = Text.Search.new text_api_endpoint tag_search difficulty_search

    text_search =
      (case profile of
        User.Profile.Student student_profile ->
          case Student.Profile.studentDifficultyPreference student_profile of
            Just difficulty ->
              Text.Search.add_difficulty_to_search default_search (Tuple.first difficulty) True

            _ ->
              default_search

        _ ->
          default_search)
  in
    ({
      results=[]
    , profile=profile
    , text_search=text_search
    , flags=flags
    }
    , update_results text_search)

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
        new_text_search = Text.Search.add_difficulty_to_search model.text_search difficulty select
      in
        ({ model | text_search = new_text_search, results = [] }, update_results new_text_search)

    SelectTag tag_name selected ->
      let
        tag_search = Text.Search.tag_search model.text_search
        tag_search_input_id = Text.Search.Tag.input_id tag_search
        new_tag_search = Text.Search.Tag.select_tag tag_search tag_name selected
        new_text_search = Text.Search.set_tag_search model.text_search new_tag_search
      in
        ({ model | text_search = new_text_search, results = [] }
        , Cmd.batch [clearInputText tag_search_input_id, update_results new_text_search])

    TextSearch result ->
      case result of
        Ok texts ->
          ({ model | results = texts }, Cmd.none)
        Err err -> let _ = Debug.log "error retrieving results" err in
          (model, Cmd.none)

    LogOut msg ->
        (model, User.Profile.logout model.profile model.flags.csrftoken LoggedOut)

    LoggedOut (Ok logout_resp) ->
      (model, Ports.redirect logout_resp.redirect)

    LoggedOut (Err err) ->
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
    view_tag tag_search_option =
      let
        selected = Text.Search.Option.selected tag_search_option
        tag_value = Text.Search.Option.value tag_search_option
        tag_label = Text.Search.Option.label tag_search_option
      in
        div [ onClick (SelectTag tag_value (not selected))
            , classList [("text_tag", True)
            , ("text_tag_selected", selected)] ] [
          Html.text tag_label
        ]
  in
    div [id "text_tags"] [
      div [class "text_tags"] (List.map view_tag (Dict.values tags))
    ]

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
  div [id "text_search_filters"] [
    div [id "text_search_filters_label"] [ Html.text "Filters" ]
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
        sections_complete =
          (case text_item.text_sections_complete of
            Just sections_complete ->
              toString sections_complete ++ " / " ++ toString text_item.text_section_count
            Nothing ->
              "0 / " ++ toString text_item.text_section_count)
      in
        div [class "search_result"] [
          div [class "result_item"] [
            div [class "result_item_title"] [ Html.a [attribute "href" text_item.uri] [ Html.text text_item.title ] ]
          , div [class "sub_description"] [ Html.text "Title" ]
          ]
        , div [class "result_item"] [
            div [class "result_item_title"] [ Html.text text_item.difficulty ]
          , div [class "sub_description"] [ Html.text "Difficulty" ]
          ]
        , div [class "result_item"] [
            div [class "result_item_title"] [ Html.text text_item.author ]
          , div [class "sub_description"] [ Html.text "Author" ]
          ]
        , div [class "result_item"] [
            div [class "result_item_title"] [ Html.text sections_complete ]
          , div [class "sub_description"] [ Html.text "Sections Complete" ]
          ]
        , div [class "result_item"] [
            div [class "result_item_title"] [ Html.text tags ]
          , div [class "sub_description"] [ Html.text "Tags" ]
          ]
        ]
  in
    div [id "text_search_results"] (List.map view_search_result text_list_items)

view_search_footer : Model -> Html Msg
view_search_footer model =
  let
    results_length = List.length model.results
    entries = if results_length == 1 then "entry" else "entries"
  in
    div [id "footer_items"] [
      div [id "footer", class "message"] [
          Html.text <| String.join " " ["Showing", toString results_length, entries]
      ]
    ]

view_help_msg : Model -> Html Msg
view_help_msg model =
  div [id "text_search_help_msg"] [
    Html.text """TIP: Use this page to find texts for your proficiency level and on topics that are of interest to you."""
  ]

view_content : Model -> Html Msg
view_content model =
  div [id "text_search"] [
    view_search_filters model
  , view_help_msg model
  , view_search_results model.results
  , view_search_footer model
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    Views.view_header model.profile (Just 0) LogOut
  , view_content model
  , Views.view_footer
  ]
