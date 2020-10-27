module User.SignUp exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick, onInput)
import Menu.Msg as MenuMsg
import Utils exposing (isValidEmail)
import Views


type UserID
    = UserID Int


type RedirectURI
    = RedirectURI URI


type URI
    = URI String


redirectURI : RedirectURI -> URI
redirectURI (RedirectURI uri) =
    uri


uriToString : URI -> String
uriToString (URI uri) =
    uri


signupLabel : Html msg -> Html msg
signupLabel html =
    Html.div [ attribute "class" "signup_label" ] [ html ]


validationError : Html msg -> Html msg
validationError html =
    div [ class "validation-error" ]
        [ html
        ]


submit : { b | errors : Dict comparable v } -> { b | errors : Dict comparable v }
submit model =
    { model | errors = Dict.fromList [] }


update_email :
    { c | signup_params : { b | email : String }, errors : Dict String String }
    -> String
    ->
        { c
            | errors : Dict String String
            , signup_params : { b | email : String }
        }
update_email model addr =
    let
        signup_params =
            model.signup_params
    in
    { model
        | signup_params = { signup_params | email = addr }
        , errors =
            if isValidEmail addr || (addr == "") then
                Dict.remove "email" model.errors

            else
                Dict.insert "email" "This e-mail is invalid" model.errors
    }


update_confirm_password :
    { a
        | signup_params : { b | confirm_password : String, password : String }
        , errors : Dict String String
    }
    -> String
    ->
        { a
            | errors : Dict String String
            , signup_params : { b | password : String, confirm_password : String }
        }
update_confirm_password model confirm_password =
    let
        signup_params =
            model.signup_params
    in
    { model
        | signup_params = { signup_params | confirm_password = confirm_password }
        , errors =
            if confirm_password == model.signup_params.password then
                Dict.remove "password" (Dict.remove "confirm_password" model.errors)

            else
                Dict.insert "confirm_password" "Passwords don't match." model.errors
    }


update_password :
    { a | signup_params : { b | password : String } }
    -> String
    -> { a | signup_params : { b | password : String } }
update_password model password =
    let
        signup_params =
            model.signup_params
    in
    { model | signup_params = { signup_params | password = password } }


toggle_show_password : { a | show_passwords : Bool } -> { a | show_passwords : Bool }
toggle_show_password model =
    { model
        | show_passwords =
            if model.show_passwords then
                False

            else
                True
    }


view_email_input :
    (String -> msg)
    -> { a | errors : Dict String String }
    -> List (Html msg)
view_email_input update_email_msg model =
    let
        errMsgHTML =
            case Dict.get "email" model.errors of
                Just errMsg ->
                    validationError (Html.em [] [ Html.text errMsg ])

                Nothing ->
                    Html.text ""

        email_error =
            if Dict.member "email" model.errors then
                [ attribute "class" "input_error" ]

            else
                []
    in
    [ signupLabel (Html.text "Email Address")
    , Html.input ([ attribute "size" "25", onInput update_email_msg ] ++ email_error) []
    , errMsgHTML
    ]


view_password_input :
    ( msg, String -> msg, String -> msg )
    -> { a | show_passwords : Bool, errors : Dict String String }
    -> List (Html msg)
view_password_input ( toggle_msg, update_msg, update_confirm_msg ) model =
    let
        confirm_err_msg =
            case Dict.get "confirm_password" model.errors of
                Just err_msg ->
                    validationError (Html.em [] [ Html.text err_msg ])

                Nothing ->
                    Html.text ""

        password_err_msg =
            case Dict.get "password" model.errors of
                Just err_msg ->
                    validationError (Html.em [] [ Html.text err_msg ])

                Nothing ->
                    Html.text ""

        pass_err =
            Dict.member "confirm_password" model.errors || Dict.member "password" model.errors

        attrs =
            [ attribute "size" "35" ]
                ++ (if pass_err then
                        [ attribute "class" "input_error" ]

                    else
                        []
                   )
                ++ (if model.show_passwords then
                        [ attribute "type" "text" ]

                    else
                        [ attribute "type" "password" ]
                   )
    in
    [ signupLabel
        (Html.span []
            [ Html.text "Password "
            , Html.span [ onClick toggle_msg, attribute "class" "cursor" ] [ Html.text "(show)" ]
            ]
        )
    , Html.input (attrs ++ [ onInput update_msg ]) []
    , password_err_msg
    , signupLabel (Html.text "Confirm Password")
    , Html.input (attrs ++ [ onInput update_confirm_msg ]) []
    , confirm_err_msg
    ]


view_submit : msg -> a -> List (Html msg)
view_submit submit_msg model =
    [ signupLabel
        (div [ class "button", onClick submit_msg, class "cursor" ]
            [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ] ]
        )
    ]


viewInternalErrorMessage : Dict String String -> List (Html msg)
viewInternalErrorMessage errors =
    let
        dbg =
            Debug.log "errs" errors
    in
    case Dict.get "internal" errors of
        Just err_msg ->
            [ validationError (Html.em [] [ Html.text err_msg ]) ]

        Nothing ->
            []


view_content :
    String
    -> (String -> a)
    -> ( a, String -> a, String -> a )
    -> a
    -> { b | show_passwords : Bool, errors : Dict String String }
    -> Html a
view_content signupLabelText email_msg password_msgs submit_msg model =
    div [ classList [ ( "signup", True ) ] ]
        [ div [ class "signup_title" ] [ Html.text signupLabelText ]
        , div [ classList [ ( "signup_box", True ) ] ] <|
            view_email_input email_msg model
                ++ view_password_input password_msgs model
                ++ viewInternalErrorMessage model.errors
                ++ view_submit submit_msg model
        ]



-- VIEW


view :
    String
    -> (String -> msg)
    -> ( msg, String -> msg, String -> msg )
    -> msg
    -> (MenuMsg.Msg -> msg)
    -> { a | show_passwords : Bool, errors : Dict String String }
    -> Html msg
view signup_label email_msg password_msgs submit_msg logout_msg model =
    div []
        [ Views.view_unauthed_header
        , view_content signup_label email_msg password_msgs submit_msg model
        , Views.view_footer
        ]
