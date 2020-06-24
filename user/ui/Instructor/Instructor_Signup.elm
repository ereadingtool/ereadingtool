module Instructor.Instructor_Signup exposing (Flags, InstructorSignUpURI(..), InviteCode, Model, Msg(..), SignUpParams, SignUpResp, flagsToInstructorSignUpURI, init, instructorSignUpURI, instructor_signup_view, isValidInviteCodeLength, main, postSignup, redirect, signUpEncoder, signUpRespDecoder, subscriptions, update, updateInviteCode, view_invite_code_input)

import Dict exposing (Dict)
import Flags
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onInput)
import Http exposing (..)
import HttpHelpers exposing (post_with_headers)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required, resolve)
import Json.Encode as Encode
import Menu.Msg as MenuMsg
import Navigation
import SignUp
import User.Flags.UnAuthed exposing (UnAuthedUserFlags)
import Views


type InstructorSignUpURI
    = InstructorSignUpURI SignUp.URI


instructorSignUpURI : InstructorSignUpURI -> SignUp.URI
instructorSignUpURI (InstructorSignUpURI uri) =
    uri


type alias SignUpResp =
    { id : SignUp.UserID, redirect : SignUp.RedirectURI }


type alias Flags =
    UnAuthedUserFlags { instructor_signup_uri : String }


type alias InviteCode =
    String


type alias SignUpParams =
    { email : String
    , password : String
    , confirm_password : String
    , invite_code : InviteCode
    }


type Msg
    = ToggleShowPassword
    | UpdateEmail String
    | UpdatePassword String
    | UpdateConfirmPassword String
    | UpdateInviteCode String
    | Submitted (Result Http.Error SignUpResp)
    | Submit
    | Logout MenuMsg.Msg


type alias Model =
    { flags : Flags
    , signup_params : SignUpParams
    , signup_uri : InstructorSignUpURI
    , show_passwords : Bool
    , errors : Dict String String
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signup_params =
    Encode.object
        [ ( "email", Encode.string signup_params.email )
        , ( "password", Encode.string signup_params.password )
        , ( "confirm_password", Encode.string signup_params.confirm_password )
        , ( "invite_code", Encode.string signup_params.invite_code )
        ]


signUpRespDecoder : Decode.Decoder SignUpResp
signUpRespDecoder =
    decode SignUpResp
        |> required "id" (Decode.map SignUp.UserID Decode.int)
        |> required "redirect" (Decode.map (SignUp.URI >> SignUp.RedirectURI) Decode.string)


redirect : SignUp.RedirectURI -> Cmd msg
redirect redirect_uri =
    Navigation.load (SignUp.uriToString (SignUp.redirectURI redirect_uri))


postSignup : Flags.CSRFToken -> InstructorSignUpURI -> SignUpParams -> Cmd Msg
postSignup csrftoken instructor_signup_api_endpoint signup_params =
    let
        encoded_signup_params =
            signUpEncoder signup_params

        req =
            post_with_headers
                (SignUp.uriToString (instructorSignUpURI instructor_signup_api_endpoint))
                [ Http.header "X-CSRFToken" csrftoken ]
                (Http.jsonBody encoded_signup_params)
                signUpRespDecoder
    in
    Http.send Submitted req


flagsToInstructorSignUpURI : { a | instructor_signup_uri : String } -> InstructorSignUpURI
flagsToInstructorSignUpURI flags =
    InstructorSignUpURI (SignUp.URI flags.instructor_signup_uri)


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { flags = flags
      , signup_params =
            { email = ""
            , password = ""
            , confirm_password = ""
            , invite_code = ""
            }
      , signup_uri = flagsToInstructorSignUpURI flags
      , show_passwords = False
      , errors = Dict.fromList []
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword ->
            ( SignUp.toggle_show_password model, Cmd.none )

        UpdatePassword password ->
            ( SignUp.update_password model password, Cmd.none )

        UpdateConfirmPassword confirm_password ->
            ( SignUp.update_confirm_password model confirm_password, Cmd.none )

        UpdateEmail addr ->
            ( SignUp.update_email model addr, Cmd.none )

        UpdateInviteCode invite_code ->
            ( updateInviteCode model invite_code, Cmd.none )

        Submit ->
            ( model, postSignup model.flags.csrftoken model.signup_uri model.signup_params )

        Submitted (Ok resp) ->
            ( model, redirect resp.redirect )

        Submitted (Err err) ->
            case err of
                Http.BadStatus resp ->
                    case Decode.decodeString (Decode.dict Decode.string) resp.body of
                        Ok errors ->
                            ( { model | errors = errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload err resp ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Logout msg ->
            ( model, Cmd.none )


isValidInviteCodeLength : InviteCode -> ( Bool, Maybe String )
isValidInviteCodeLength invite_code =
    case String.length invite_code > 64 of
        True ->
            ( False, Just "too long" )

        False ->
            case String.length invite_code < 64 of
                True ->
                    ( False, Just "too short" )

                False ->
                    ( True, Nothing )


updateInviteCode : Model -> InviteCode -> Model
updateInviteCode model invite_code =
    let
        signup_params =
            model.signup_params

        ( valid_invite_code, invite_code_err ) =
            isValidInviteCodeLength invite_code
    in
    { model
        | signup_params = { signup_params | invite_code = invite_code }
        , errors =
            if valid_invite_code || (invite_code == "") then
                Dict.remove "invite_code" model.errors

            else
                Dict.insert
                    "invite_code"
                    ("This invite code is " ++ Maybe.withDefault "" invite_code_err ++ ".")
                    model.errors
    }


view_invite_code_input : Model -> List (Html Msg)
view_invite_code_input model =
    let
        err =
            Dict.member "invite_code" model.errors

        err_msg =
            [ SignUp.signup_label
                (Html.em [] [ Html.text (Maybe.withDefault "" (Dict.get "invite_code" model.errors)) ])
            ]
    in
    [ SignUp.signup_label (Html.span [] [ Html.text "Invite Code " ])
    , Html.input
        ([ attribute "size" "25", onInput UpdateInviteCode ]
            ++ (if err then
                    [ attribute "class" "input_error" ]

                else
                    []
               )
        )
        []
    ]
        ++ (if err then
                err_msg

            else
                []
           )


instructor_signup_view : Model -> Html Msg
instructor_signup_view model =
    div []
        [ Views.view_unauthed_header
        , div [ classList [ ( "signup", True ) ] ]
            [ div [ class "signup_title" ] [ Html.text "Instructor Signup" ]
            , div [ classList [ ( "signup_box", True ) ] ] <|
                SignUp.view_email_input UpdateEmail model
                    ++ SignUp.view_password_input ( ToggleShowPassword, UpdatePassword, UpdateConfirmPassword ) model
                    ++ view_invite_code_input model
                    ++ SignUp.view_submit Submit model
            ]
        , Views.view_footer
        ]


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = instructor_signup_view
        , subscriptions = subscriptions
        , update = update
        }
