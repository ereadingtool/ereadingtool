import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Json.Encode as Encode

import Dict exposing (Dict)

import Profile exposing (StudentProfile)

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
profileEncoder student = let
  encode_pref = (case (Profile.studentDifficultyPreference student) of
    Just difficulty -> Encode.string (Tuple.first difficulty)
    _ -> Encode.null) in Encode.object [
     ("difficulty_preference", encode_pref)
  ]

updateRespDecoder : Decode.Decoder (UpdateProfileResp)
updateRespDecoder = Decode.dict Decode.string

post_profile : Flags.CSRFToken -> Profile.StudentProfile -> Cmd Msg
post_profile csrftoken profile =
  let encoded_profile = profileEncoder profile
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
view_difficulty model = let pref = (case Profile.studentDifficultyPreference model.profile of
  Just pref -> Tuple.first pref
  _ -> "") in Html.div [classList [("profile_item", True)] ] [
    Html.select [
         onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++
            (if k == pref then [attribute "selected" ""] else []))
           [ Html.text v ]) (Profile.studentDifficulties model.profile))
       ]
  ]

view_content : Model -> Html Msg
view_content model = Html.div [ classList [("profile", True)] ] [
    Html.div [classList [("profile_items", True)] ] [
        Html.span [] [Html.text "Username: ", Html.text (Profile.studentUserName model.profile)]
      , Html.text "Preferred Difficulty", (view_difficulty model)
      , (if not (String.isEmpty model.err_str) then
          Html.span [attribute "class" "error"] [ Html.text "error", Html.text model.err_str ]
        else Html.text "")]
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (Views.view_header (Profile.fromStudentProfile model.profile) Nothing)
  , (Views.view_filter)
  , (view_content model)
  , (Views.view_footer)
  ]
