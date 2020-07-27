module User.Login exposing (..)

import Dict exposing (Dict)
import Flags
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Utils.HttpHelpers exposing (post_with_headers)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Browser.Navigation
import User
import User.Flags.UnAuthed exposing (UnAuthedUserFlags)
import Utils exposing (isValidEmail)
import Views


type alias LoginResp =
    { id : User.UserID, redirect : User.RedirectURI }


type alias Flags =
    UnAuthedUserFlags {}



-- UPDATE


type Msg
    = Submit
    | Submitted (Result Http.Error LoginResp)
    | UpdateEmail String
    | UpdatePassword String


type Login
    = StudentLogin User.SignUpURL User.LoginURI User.LoginPageURL User.ForgotPassURL
    | InstructorLogin User.SignUpURL User.LoginURI User.LoginPageURL User.ForgotPassURL


type alias LoginParams =
    { username : String
    , password : String
    }


type alias Model =
    { flags : Flags
    , login_params : LoginParams
    , login : Login
    , acknowledgements_page_url : User.AcknowledgePageURL
    , about_page_url : User.AboutPageURL
    , errors : Dict String String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        login =
            flagsToLogin flags
    in
    ( { flags = flags
      , login_params = LoginParams "" ""
      , login = login
      , about_page_url = flagsToAboutURL flags
      , acknowledgements_page_url = flagsToAcknowledgementURL flags
      , errors = Dict.fromList []
      }
    , Cmd.none
    )


flagsToLogin : Flags -> Login
flagsToLogin flags =
    if flags.user_type == "instructor" then
        InstructorLogin
            (User.SignUpURL (User.URL flags.signup_page_url))
            (User.LoginURI (User.URI flags.login_uri))
            (User.LoginPageURL (User.URL flags.login_page_url))
            (User.ForgotPassURL (User.URL flags.forgot_password_url))

    else
        StudentLogin
            (User.SignUpURL (User.URL flags.signup_page_url))
            (User.LoginURI (User.URI flags.login_uri))
            (User.LoginPageURL (User.URL flags.login_page_url))
            (User.ForgotPassURL (User.URL flags.forgot_password_url))


flagsToAboutURL : { a | about_url : String } -> User.AboutPageURL
flagsToAboutURL flags =
    User.AboutPageURL (User.URL flags.about_url)


flagsToAcknowledgementURL : { a | acknowledgements_url : String } -> User.AcknowledgePageURL
flagsToAcknowledgementURL flags =
    User.AcknowledgePageURL (User.URL flags.acknowledgements_url)


loginURI : Login -> User.LoginURI
loginURI login =
    case login of
        StudentLogin _ login_uri _ _ ->
            login_uri

        InstructorLogin _ login_uri _ _ ->
            login_uri


signupURI : Login -> User.SignUpURL
signupURI login =
    case login of
        StudentLogin signup_uri _ _ _ ->
            signup_uri

        InstructorLogin signup_uri _ _ _ ->
            signup_uri


forgotPassURL : Login -> User.ForgotPassURL
forgotPassURL login =
    case login of
        StudentLogin _ _ _ forgot_pass_url ->
            forgot_pass_url

        InstructorLogin _ _ _ forgot_pass_url ->
            forgot_pass_url


loginPageURL : Login -> User.LoginPageURL
loginPageURL login =
    case login of
        StudentLogin _ _ login_page_url _ ->
            login_page_url

        InstructorLogin _ _ login_page_url _ ->
            login_page_url


label : Login -> String
label login =
    case login of
        StudentLogin _ _ _ _ ->
            "Student Login"

        InstructorLogin _ _ _ _ ->
            "Instructor Login"


student_login : User.SignUpURL -> User.LoginURI -> User.LoginPageURL -> User.ForgotPassURL -> Login
student_login signup_uri login_uri login_page_url forgot_pass_url =
    StudentLogin signup_uri login_uri login_page_url forgot_pass_url


instructor_login : User.SignUpURL -> User.LoginURI -> User.LoginPageURL -> User.ForgotPassURL -> Login
instructor_login signup_uri login_uri login_page_url forgot_pass_url =
    InstructorLogin signup_uri login_uri login_page_url forgot_pass_url


loginEncoder : LoginParams -> Encode.Value
loginEncoder login_params =
    Encode.object
        [ ( "username", Encode.string login_params.username )
        , ( "password", Encode.string login_params.password )
        ]


redirect : User.RedirectURI -> Cmd msg
redirect redirect_uri =
    Browser.Navigation.load (User.uriToString (User.redirectURI redirect_uri))


loginRespDecoder : Json.Decode.Decoder LoginResp
loginRespDecoder =
    Json.Decode.succeed LoginResp
        |> required "id" (Json.Decode.map User.UserID Json.Decode.int)
        |> required "redirect" (Json.Decode.map (User.URI >> User.RedirectURI) Json.Decode.string)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


post_login : User.LoginURI -> Flags.CSRFToken -> LoginParams -> Cmd Msg
post_login endpoint csrftoken login_params =
    let
        encoded_login_params =
            loginEncoder login_params

        req =
            post_with_headers
                (User.uriToString (User.loginURI endpoint))
                [ Http.header "X-CSRFToken" csrftoken ]
                (Http.jsonBody encoded_login_params)
                loginRespDecoder
    in
    Http.send Submitted req


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdatePassword password ->
            let
                login_params =
                    model.login_params
            in
            ( { model | login_params = { login_params | password = password } }, Cmd.none )

        UpdateEmail addr ->
            let
                login_params =
                    model.login_params
            in
            ( { model
                | login_params = { login_params | username = addr }
                , errors =
                    if isValidEmail addr || (addr == "") then
                        Dict.remove "email" model.errors

                    else
                        Dict.insert "email" "This e-mail is invalid" model.errors
              }
            , Cmd.none
            )

        Submit ->
            ( { model | errors = Dict.fromList [] }
            , post_login (loginURI model.login) model.flags.csrftoken model.login_params
            )

        Submitted (Ok resp) ->
            ( model, redirect resp.redirect )

        Submitted (Err error) ->
            case error of
                Http.BadStatus resp ->
                    case Json.Decode.decodeString (Json.Decode.dict Json.Decode.string) resp.body of
                        Ok errors ->
                            ( { model | errors = errors }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Http.BadPayload _ _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


login_label : List (Html.Attribute Msg) -> Html Msg -> Html Msg
login_label attributes html =
    div ([ attribute "class" "login_label" ] ++ attributes)
        [ html
        ]


view_email_input : Model -> List (Html Msg)
view_email_input model =
    let
        errorHTML =
            case Dict.get "email" model.errors of
                Just errorMsg ->
                    login_label [] (Html.em [] [ Html.text errorMsg ])

                Nothing ->
                    Html.text ""
    in
    let
        email_error =
            if Dict.member "email" model.errors then
                [ attribute "class" "input_error" ]

            else
                []
    in
    [ login_label [] (span [] [ Html.text "E-mail Address:" ])
    , Html.input
        ([ attribute "size" "25"
         , onInput UpdateEmail
         ]
            ++ email_error
        )
        []
    , errorHTML
    ]


view_password_input : Model -> List (Html Msg)
view_password_input model =
    let
        password_err_msg =
            case Dict.get "password" model.errors of
                Just err_msg ->
                    login_label [] (Html.em [] [ Html.text err_msg ])

                Nothing ->
                    Html.text ""

        pass_err =
            Dict.member "password" model.errors

        attrs =
            [ attribute "size" "35", attribute "type" "password" ]
                ++ (if pass_err then
                        [ attribute "class" "input_error" ]

                    else
                        []
                   )
    in
    [ login_label []
        (span []
            [ Html.text "Password:"
            ]
        )
    , Html.input (attrs ++ [ onInput UpdatePassword, Util.onEnterUp Submit ]) []
    , password_err_msg
    ]


view_errors : Model -> List (Html Msg)
view_errors model =
    case Dict.get "all" model.errors of
        Just all_err ->
            [ login_label [] (span [ attribute "class" "errors" ] [ Html.em [] [ Html.text <| all_err ] ]) ]

        _ ->
            [ span [ attribute "class" "errors" ] [] ]


view_submit : Model -> List (Html Msg)
view_submit model =
    [ login_label [ class "button", onClick Submit, class "cursor" ]
        (div [ class "login_submit" ] [ span [] [ Html.text "Login" ] ])
    ]


view_other_login_option : Login -> Html Msg
view_other_login_option login =
    let
        login_url =
            User.urlToString (User.loginPageURL (loginPageURL login))
    in
    case login of
        StudentLogin _ _ _ _ ->
            div []
                [ Html.text "Are you a content editor? "
                , Html.a [ attribute "href" login_url ]
                    [ span [ attribute "class" "cursor" ]
                        [ Html.text "Login as a content editor"
                        ]
                    ]
                ]

        InstructorLogin _ _ _ _ ->
            div []
                [ Html.text "Are you a student? "
                , Html.a [ attribute "href" login_url ]
                    [ span [ attribute "class" "cursor" ]
                        [ Html.text "Login as an student"
                        ]
                    ]
                ]


view_login : Login -> List (Html Msg)
view_login login =
    [ span [ class "login_options" ]
        [ view_not_registered (signupURI login)
        , view_forgot_password (forgotPassURL login)
        , view_other_login_option login
        ]
    ]


view_not_registered : User.SignUpURL -> Html Msg
view_not_registered signup_uri =
    div []
        [ Html.text "Not registered? "
        , Html.a [ attribute "href" (User.urlToString (User.signupURL signup_uri)) ]
            [ span [ attribute "class" "cursor" ] [ Html.text "Sign Up" ]
            ]
        ]


view_forgot_password : User.ForgotPassURL -> Html Msg
view_forgot_password forgot_pass_url =
    div []
        [ Html.text "Forgot Password? "
        , Html.a [ attribute "href" (User.urlToString (User.forgotPassURL forgot_pass_url)) ]
            [ span [ attribute "class" "cursor" ]
                [ Html.text "Reset Password"
                ]
            ]
        ]


view_content : Model -> Html Msg
view_content model =
    div [ classList [ ( "login", True ) ] ]
        [ div [ class "login_type" ] [ Html.text (label model.login) ]
        , div [ classList [ ( "login_box", True ) ] ] <|
            view_email_input model
                ++ view_password_input model
                ++ view_login model.login
                ++ view_submit model
                ++ view_errors model
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Views.view_unauthed_header
        , view_content model
        , Views.view_footer
        ]
