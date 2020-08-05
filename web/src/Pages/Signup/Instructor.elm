module Pages.Signup.Instructor exposing
    ( Model
    , Msg
    , Params
    , init
    , page
    , subscriptions
    , update
    )

import Api exposing (post)
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onInput)
import Http exposing (..)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Menu.Msg as MenuMsg
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.SignUp as SignUp
import Views


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }


type alias InviteCode =
    String


type alias SignUpParams =
    { email : String
    , password : String
    , confirm_password : String
    , invite_code : InviteCode
    }


type alias SignUpResp =
    { id : SignUp.UserID
    , redirect : SignUp.RedirectURI
    }



-- INIT


type alias Params =
    ()


type alias Model =
    { session : Session
    , config : Config
    , navKey : Key
    , signup_params : SignUpParams
    , show_passwords : Bool
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , navKey = shared.key
      , signup_params =
            { email = ""
            , password = ""
            , confirm_password = ""
            , invite_code = ""
            }
      , show_passwords = False
      , errors = Dict.fromList []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ToggleShowPassword
    | UpdateEmail String
    | UpdatePassword String
    | UpdateConfirmPassword String
    | UpdateInviteCode String
    | Submitted (Result Http.Error SignUpResp)
    | Submit
    | Logout MenuMsg.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword ->
            ( SignUp.toggle_show_password model, Cmd.none )

        UpdatePassword password ->
            ( SignUp.update_password model password, Cmd.none )

        UpdateConfirmPassword confirmPassword ->
            ( SignUp.update_confirm_password model confirmPassword, Cmd.none )

        UpdateEmail addr ->
            ( SignUp.update_email model addr, Cmd.none )

        UpdateInviteCode inviteCode ->
            ( updateInviteCode model inviteCode, Cmd.none )

        Submit ->
            ( model, postSignup model.session model.config model.signup_params )

        Submitted (Ok resp) ->
            ( model
            , Browser.Navigation.replaceUrl model.navKey (SignUp.uriToString (SignUp.redirectURI resp.redirect))
            )

        Submitted (Err err) ->
            case err of
                Http.BadStatus resp ->
                    ( model, Cmd.none )

                Http.BadBody _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Logout _ ->
            ( model, Cmd.none )


updateInviteCode : Model -> InviteCode -> Model
updateInviteCode model inviteCode =
    let
        signupParams =
            model.signup_params

        ( validInviteCode, inviteCodeError ) =
            isValidInviteCodeLength inviteCode
    in
    { model
        | signup_params = { signupParams | invite_code = inviteCode }
        , errors =
            if validInviteCode || (inviteCode == "") then
                Dict.remove "invite_code" model.errors

            else
                Dict.insert
                    "invite_code"
                    ("This invite code is " ++ Maybe.withDefault "" inviteCodeError ++ ".")
                    model.errors
    }


isValidInviteCodeLength : InviteCode -> ( Bool, Maybe String )
isValidInviteCodeLength inviteCode =
    if String.length inviteCode > 64 then
        ( False, Just "too long" )

    else if String.length inviteCode < 64 then
        ( False, Just "too short" )

    else
        ( True, Nothing )


postSignup : Session -> Config -> SignUpParams -> Cmd Msg
postSignup session config signupParams =
    let
        encodedSignupParams =
            signUpEncoder signupParams
    in
    Api.post
        (Endpoint.instructorSignup (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedSignupParams)
        Submitted
        signUpRespDecoder


signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signupParams =
    Encode.object
        [ ( "email", Encode.string signupParams.email )
        , ( "password", Encode.string signupParams.password )
        , ( "confirm_password", Encode.string signupParams.confirm_password )
        , ( "invite_code", Encode.string signupParams.invite_code )
        ]


signUpRespDecoder : Json.Decode.Decoder SignUpResp
signUpRespDecoder =
    Json.Decode.succeed SignUpResp
        |> required "id" (Json.Decode.map SignUp.UserID Json.Decode.int)
        |> required "redirect" (Json.Decode.map (SignUp.URI >> SignUp.RedirectURI) Json.Decode.string)



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Instructor Signup"
    , body =
        [ div []
            [ Views.view_unauthed_header
            , div [ classList [ ( "signup", True ) ] ]
                [ div [ class "signup_title" ] [ Html.text "Instructor Signup" ]
                , div [ classList [ ( "signup_box", True ) ] ] <|
                    SignUp.view_email_input UpdateEmail model
                        ++ SignUp.view_password_input ( ToggleShowPassword, UpdatePassword, UpdateConfirmPassword ) model
                        ++ viewInviteCodeInput model
                        ++ SignUp.view_submit Submit model
                ]
            , Views.view_footer
            ]
        ]
    }


viewInviteCodeInput : Model -> List (Html Msg)
viewInviteCodeInput model =
    let
        err =
            Dict.member "invite_code" model.errors

        err_msg =
            [ SignUp.signupLabel
                (Html.em [] [ Html.text (Maybe.withDefault "" (Dict.get "invite_code" model.errors)) ])
            ]
    in
    [ SignUp.signupLabel (Html.span [] [ Html.text "Invite Code " ])
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



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
