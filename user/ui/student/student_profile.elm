import Html exposing (Html, div)
import Html.Attributes exposing (classList, attribute)
import Html.Events exposing (onClick, onBlur, onInput, onMouseOver, onCheck, onMouseOut, onMouseLeave)

import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Json.Encode as Encode

import Dict exposing (Dict)
import Debug

import Model exposing (StudentProfile, studentProfileDecoder)

import Views exposing (view_filter, view_header, view_footer)
import Config exposing (student_api_endpoint)
import Flags exposing (CSRFToken, ProfileID, ProfileType)

-- UPDATE
type Msg =
    UpdateStudentProfile (Result Error StudentProfile)
  | UpdateDifficulty String
  | Submitted (Result Error UpdateProfileResp )

type alias Flags = {
    csrftoken : CSRFToken
  , profile_id : ProfileID
  , profile_type: ProfileType }

type alias Model = {
    flags : Flags
  , profile : StudentProfile
  , err_str : String
  , errors : Dict String String }

type alias UpdateProfileResp = Dict.Dict String String

profileEncoder : StudentProfile -> Encode.Value
profileEncoder profile = let
  encode_pref = (case profile.difficulty_preference of
    Just difficulty -> Encode.string (Tuple.first difficulty)
    _ -> Encode.null) in Encode.object [
     ("difficulty_preference", encode_pref)
  ]

updateRespDecoder : Decode.Decoder (UpdateProfileResp)
updateRespDecoder = Decode.dict Decode.string

post_profile : CSRFToken -> StudentProfile -> Cmd Msg
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
  , profile = StudentProfile Nothing Nothing [] ""
  , err_str = "", errors = Dict.fromList [] }, update_student_profile flags.profile_id)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update_student_profile : ProfileID -> Cmd Msg
update_student_profile profile_id =  let
    request = Http.get (String.join "" [student_api_endpoint, (toString profile_id) ++ "/"]) studentProfileDecoder
  in Http.send UpdateStudentProfile request

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  UpdateStudentProfile (Ok profile) ->
    ({ model | profile = (Debug.log "profile" profile) }, Cmd.none)

  -- handle user-friendly msgs
  UpdateStudentProfile (Err err) ->
    ({ model | err_str = (Debug.log "err" (toString err))}, Cmd.none)

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
view_difficulty model = let pref = (case model.profile.difficulty_preference of
  Just pref -> Tuple.first pref
  _ -> "") in Html.div [classList [("profile_item", True)] ] [
    Html.select [
         onInput UpdateDifficulty ] [
        Html.optgroup [] (List.map (\(k,v) ->
          Html.option ([attribute "value" k] ++
            (if v == pref then [attribute "selected" ""] else []))
           [ Html.text v ]) model.profile.difficulties)
       ]
  ]

view_content : Model -> Html Msg
view_content model = Html.div [ classList [("profile", True)] ] [
    Html.div [classList [("profile_items", True)] ] [
        Html.span [] [Html.text "Username: ", Html.text model.profile.username]
      , Html.text "Preferred Difficulty", (view_difficulty model)
      , (if not (String.isEmpty model.err_str) then
          Html.span [attribute "class" "error"] [ Html.text "error", Html.text model.err_str ]
        else Html.text "")]
  ]

-- VIEW
view : Model -> Html Msg
view model = div [] [
    (view_header)
  , (view_filter)
  , (view_content model)
  , (view_footer)
  ]
