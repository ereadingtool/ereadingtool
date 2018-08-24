import Html exposing (Html, div, span)
import Html.Attributes exposing (class, classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Json.Encode as Encode

import Dict exposing (Dict)

import Profile exposing (StudentProfile, TextReading)

import Views
import Config exposing (student_api_endpoint)
import Flags

-- UPDATE
type Msg =
    UpdateStudentProfile (Result Error Profile.StudentProfile)
  | UpdateDifficulty String
  | Submitted (Result Error UpdateProfileResp )

type alias Flags = Flags.Flags {}

type alias Model = {
    flags : Flags
  , profile : Profile.StudentProfile
  , err_str : String
  , errors : Dict String String }

type alias UpdateProfileResp = Dict.Dict String String

profileEncoder : Profile.StudentProfile -> Encode.Value
profileEncoder student =
  let
    encode_pref =
      (case (Profile.studentDifficultyPreference student) of
        Just difficulty ->
          Encode.string (Tuple.first difficulty)
        _ ->
          Encode.null)
  in
    Encode.object [ ("difficulty_preference", encode_pref) ]

updateRespDecoder : Decode.Decoder (UpdateProfileResp)
updateRespDecoder = Decode.dict Decode.string

post_profile : Flags.CSRFToken -> Profile.StudentProfile -> Cmd Msg
post_profile csrftoken profile =
  let
    encoded_profile = profileEncoder profile
    req =
      post_with_headers
       student_api_endpoint
       [Http.header "X-CSRFToken" csrftoken]
       (Http.jsonBody encoded_profile)
       updateRespDecoder
  in
    Http.send Submitted req

init : Flags -> (Model, Cmd Msg)
init flags = ({
    flags = flags
  , profile = Profile.emptyStudentProfile
  , err_str = "", errors = Dict.fromList [] }, Profile.retrieve_student_profile UpdateStudentProfile flags.profile_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  UpdateStudentProfile (Ok profile) ->
    ({ model | profile = profile }, Cmd.none)

  -- handle user-friendly msgs
  UpdateStudentProfile (Err err) ->
    ({ model | err_str = toString err }, Cmd.none)

  UpdateDifficulty _ -> (model, Cmd.none)

  Submitted (Ok resp) -> (model, Cmd.none)
  Submitted (Err err) -> case err of
      Http.BadStatus resp -> case (Decode.decodeString (Decode.dict Decode.string) resp.body) of
        Ok errors -> ({ model | errors = errors }, Cmd.none)
        _ -> (model, Cmd.none)
      Http.BadPayload err resp -> (model, Cmd.none)
      _ -> (model, Cmd.none)


main : Program Flags Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , subscriptions = subscriptions
    , update = update
    }

view_difficulty : Model -> Html Msg
view_difficulty model =
  let
    pref =
      (case Profile.studentDifficultyPreference model.profile of
        Just pref -> Tuple.first pref
        _ -> "")
  in
    div [] [
      Html.select [ onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++ (if k == pref then [attribute "selected" ""] else []))
         [ Html.text v ]) (Profile.studentDifficulties model.profile))
      ]
    ]

view_text_reading : TextReading -> Html Msg
view_text_reading text_reading =
  span [] [
    div [class "text_reading_item"] [
      Html.text "Text: "
    , Html.text text_reading.text
    ]
  , div [class "text_reading_item"] [
      Html.text "Current Section: "
    , Html.text (Maybe.withDefault "None" text_reading.current_section)
    ]
  , div [class "text_reading_item"] [
      Html.text "Status: "
    , Html.text text_reading.status
    ]
  , div [class "text_reading_item"] [
      Html.text "Actions"
    , div [class "text_reading_actions"] [
        div [] [ Html.a [attribute "href" ("/text/" ++ toString text_reading.id ++ "/")] [ Html.text "Resume" ] ]
      , div [] [ Html.a [attribute "href" "#"] [ Html.text "Start Over" ] ]
      ]
    ]
  ]

view_student_text_readings : StudentProfile -> Html Msg
view_student_text_readings student_profile =
  let
    text_readings = Maybe.withDefault [] (Profile.studentTextReading student_profile)
  in
    div [class "profile_item"] [
      span [class "profile_item_title"] [ Html.text "Texts In Progress" ]
    , span [class "profile_item_value"] (List.map view_text_reading text_readings)
    ]

view_content : Model -> Html Msg
view_content model =
  div [ classList [("profile", True)] ] [
    div [classList [("profile_items", True)] ] [
      div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Username" ]
      , span [class "profile_item_value"] [ Html.text (Profile.studentUserName model.profile) ]
      ]
    , div [class "profile_item"] [
        span [class "profile_item_title"] [ Html.text "Preferred Difficulty" ]
      , span [class "profile_item_value"] [ (view_difficulty model) ]
      ]
    , div [class "profile_item"] [
          span [class "profile_item_title"] [ Html.text "Flashcards: " ]
        , span [class "profile_item_value"] [
            div [] (List.map (\fake_name ->
              div [] [ Html.a [attribute "href" "#"] [ Html.text fake_name ] ]
            ) ["word", "word", "word"])
          ]
      ]
    , view_student_text_readings model.profile
    , (if not (String.isEmpty model.err_str) then
        span [attribute "class" "error"] [ Html.text "error", Html.text model.err_str ]
       else Html.text "")
    ]
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header (Profile.fromStudentProfile model.profile) Nothing)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
