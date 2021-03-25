module Pages.Signup.Student exposing
    ( Model
    , Msg
    , Params
    , page
    )

import Api
import Api.Config as Config exposing (Config)
import Api.Endpoint as Endpoint
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, id, href)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Http.Detailed
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Markdown
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import User.SignUp as SignUp
import Utils exposing (isValidEmail)


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


type alias SignUpParams =
    { email : String
    , password : String
    , confirmPassword : String
    , difficulty : String
    }


type alias SignUpResponse =
    { id : Int }



-- INIT


type alias Params =
    ()


type alias Model =
    { session : Session
    , config : Config
    , navKey : Key
    , difficulties : List ( String, String )
    , signupParams : SignUpParams
    , showPasswords : Bool
    , showDifficultyInfo : Bool
    , errors : Dict String String
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( { session = shared.session
      , config = shared.config
      , navKey = shared.key
      , difficulties = Shared.difficulties
      , signupParams =
            { email = ""
            , password = ""
            , confirmPassword = ""
            , difficulty =
                case List.head Shared.difficulties of
                    Just ( difficultyKey, difficultyName ) ->
                        difficultyKey

                    _ ->
                        ""
            }
      , showPasswords = False
      , showDifficultyInfo = False
      , errors = Dict.empty
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ToggleShowPassword
    | ToggleShowDifficultyInfo
    | UpdateEmail String
    | UpdatePassword String
    | UpdateConfirmPassword String
    | UpdateDifficulty String
    | SubmittedForm
    | CompletedSignup (Result (Http.Detailed.Error String) ( Http.Metadata, SignUpResponse ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleShowPassword ->
            ( { model | showPasswords = not model.showPasswords }
            , Cmd.none
            )

        ToggleShowDifficultyInfo ->
            ( { model | showDifficultyInfo = not model.showDifficultyInfo }
            , Cmd.none
            )

        UpdatePassword password ->
            ( model
                |> updateSignupParams (\signupParams -> { signupParams | password = password })
            , Cmd.none
            )

        UpdateConfirmPassword confirmPassword ->
            ( { model
                | errors = validatePasswordsMatch model.signupParams.password confirmPassword model.errors
              }
                |> updateSignupParams (\signupParams -> { signupParams | confirmPassword = confirmPassword })
            , Cmd.none
            )

        UpdateEmail email ->
            ( { model
                | errors = validateEmail email model.errors
              }
                |> updateSignupParams (\signupParams -> { signupParams | email = email })
            , Cmd.none
            )

        UpdateDifficulty difficulty ->
            ( model
                |> updateSignupParams (\signupParams -> { signupParams | difficulty = difficulty })
            , Cmd.none
            )

        SubmittedForm ->
            ( { model | errors = Dict.empty }
            , postSignup model.session model.config model.signupParams
            )

        CompletedSignup (Ok resp) ->
            ( model
            , Browser.Navigation.replaceUrl model.navKey (Route.toString Route.Top)
            )

        CompletedSignup (Err error) ->
            case error of
                Http.Detailed.BadStatus metadata body ->
                    ( { model | errors = errorBodyToDict body }
                    , Cmd.none
                    )

                _ ->
                    ( { model
                        | errors =
                            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]
                      }
                    , Cmd.none
                    )


updateSignupParams : (SignUpParams -> SignUpParams) -> Model -> Model
updateSignupParams transform model =
    { model | signupParams = transform model.signupParams }


validateEmail : String -> Dict String String -> Dict String String
validateEmail email errors =
    if isValidEmail email || (email == "") then
        Dict.remove "email" errors

    else
        Dict.insert "email" "This e-mail is invalid" errors


validatePasswordsMatch : String -> String -> Dict String String -> Dict String String
validatePasswordsMatch password confirmPassword errors =
    if confirmPassword == password then
        Dict.remove "password" (Dict.remove "confirm_password" errors)

    else
        Dict.insert "confirm_password" "Passwords don't match." errors


postSignup : Session -> Config -> SignUpParams -> Cmd Msg
postSignup session config signupParams =
    let
        encodedSignupParams =
            signUpEncoder signupParams
    in
    Api.postDetailed
        (Endpoint.studentSignup (Config.restApiUrl config))
        (Session.cred session)
        (Http.jsonBody encodedSignupParams)
        CompletedSignup
        signUpResponseDecoder


signUpEncoder : SignUpParams -> Encode.Value
signUpEncoder signupParams =
    Encode.object
        [ ( "email", Encode.string signupParams.email )
        , ( "password", Encode.string signupParams.password )
        , ( "confirm_password", Encode.string signupParams.confirmPassword )
        , ( "difficulty", Encode.string signupParams.difficulty )
        ]


signUpResponseDecoder : Decoder SignUpResponse
signUpResponseDecoder =
    Decode.succeed SignUpResponse
        |> required "id" Decode.int


errorBodyToDict : String -> Dict String String
errorBodyToDict body =
    case Decode.decodeString (Decode.dict Decode.string) body of
        Ok dict ->
            dict

        Err err ->
            Dict.fromList [ ( "internal", "An internal error occured. Please contact the developers." ) ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Student Signup"
    , body =
        [ div []
            [ viewContent model
            ]
        ]
    }


viewContent : Model -> Html Msg
viewContent model =
    div [ classList [ ( "signup", True ) ] ]
        [ div [ classList [ ( "signup_box", True ) ] ] <|
            div [ class "signup_title" ] [ Html.text "Student Signup" ]
                :: viewStudentWelcomeMsg
                ++ SignUp.viewEmailInput
                    { errors = model.errors
                    , onEmailInput = UpdateEmail
                    }
                ++ SignUp.viewPasswordInputs
                    { showPasswords = model.showPasswords
                    , errors = model.errors
                    , onShowPasswordToggle = ToggleShowPassword
                    , onPasswordInput = UpdatePassword
                    , onConfirmPasswordInput = UpdateConfirmPassword
                    }
                ++ viewDifficultyChoices model
                ++ viewDifficultyInfo model
                ++ SignUp.viewInternalErrorMessage model.errors
                ++ [ Html.div
                        [ attribute "class" "signup_label" ]
                        [ if
                            not (Dict.isEmpty model.errors)
                                || String.isEmpty model.signupParams.email
                                || String.isEmpty model.signupParams.password
                                || String.isEmpty model.signupParams.confirmPassword
                          then
                            div [ class "button", class "disabled" ]
                                [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ]
                                ]

                          else
                            div [ class "button", onClick SubmittedForm, class "cursor" ]
                                [ div [ class "signup_submit" ] [ Html.span [] [ Html.text "Sign Up" ] ]
                                ]
                        ]
                   ]
        ]


viewStudentWelcomeMsg : List (Html Msg)
viewStudentWelcomeMsg =
    let
        welcomeTitle =
            """Welcome to the website Steps To Advanced Reading (STAR)."""
    in
    [ div [ class "welcome_msg" ]
        [ span [ class "welcome-headline" ] [ Html.text welcomeTitle ]
        , div [ class "welcome-msg-text" ]
            [ Html.p []
                [ Html.text
                    """Developed with support from """
                    , Html.a [ href "https://www.thelanguageflagship.org/" ]
                    [ Html.text "The Language Flagship" ]
                    , Html.text 
                        """, this site is designed to help students improve their reading proficiency in Russian at a wide 
                    range of proficiency levels."""
                ]
            , Html.p [] 
                [ Html.text
                        """After signing in, you will land on a profile page, from which you can go and select a text to read. 
                    Texts are organized by proficiency level and by topic. After selecting a text, you will get a brief 
                    contextualizing message in English. Then you will see the first part of the text followed by comprehension 
                    question(s). Once you’ve read the text and selected the best answer, you will get feedback telling you if 
                    your choice is correct, and why or why not."""
                ]
            , Html.p []
                [ Html.text 
                    """On your first time using the website, pop-up boxes will guide you in learning how to use the site."""            
                ]
            ]
        ]
    ]


viewDifficultyChoices : Model -> List (Html Msg)
viewDifficultyChoices model =
    [ div [ class "input-container" ]
        [ Html.select
            [ onInput UpdateDifficulty
            ]
            [ Html.optgroup [] <|
                Html.option [ attribute "disabled" "", attribute "selected" "" ] [ Html.text "Choose a preferred difficulty:" ]
                    :: List.map
                        (\( k, v ) ->
                            Html.option
                                (attribute "value" k
                                    :: (if v == model.signupParams.difficulty then
                                            [ attribute "selected" "" ]

                                        else
                                            []
                                       )
                                )
                                [ Html.text v ]
                        )
                        model.difficulties
            ]
        , Html.span
            [ onClick ToggleShowDifficultyInfo
            , id "show-difficulty-info-button"
            ]
            [ if model.showDifficultyInfo then
                Html.img [ id "info-image", attribute "src" "/public/img/info-black.svg" ] []

              else
                Html.img [ id "info-image", attribute "src" "/public/img/info-gray.svg" ] []
            ]
        ]
    ]


viewDifficultyInfo : Model -> List (Html Msg)
viewDifficultyInfo model =
    if model.showDifficultyInfo then
        case model.signupParams.difficulty of
            "intermediate_mid" ->
                [ Markdown.toHtml [ class "difficulty-info" ] """**Texts at the Intermediate Mid level** tend to be short public announcements or 
            very brief news reports that are clearly organized. Questions will focus on your ability to recognize the 
            main ideas of the text. Typically, students in second-year Russian can attempt texts at this level. """
                ]

            "intermediate_high" ->
                [ Markdown.toHtml [ class "difficulty-info" ] """Texts at the Intermediate High level** will tend to be several paragraphs in length, 
            touching on topics of personal and/or public interest. The texts will typically describe, explain or narrate 
            some event or situation related to the topic. At the Intermediate High level, you may be able to get the main 
            idea of the text, but you might struggle with details.Typically, students in third-year and fourth-year Russian 
            can attempt texts at this level."""
                ]

            "advanced_low" ->
                [ Markdown.toHtml [ class "difficulty-info" ] """**Texts at the Advanced Low level** will be multiple paragraphs in length that 
            report and describe topics of public interest. At the Advanced Low level, you should be able to understand the 
            main ideas of the passage as well as the supporting details. Typically, strong students in fourth-year Russian 
            can attempt these texts."""
                ]

            "advanced_mid" ->
                [ Markdown.toHtml [ class "difficulty-info" ] """**Texts at the Advanced Mid level** will be even longer than at the Advanced Low 
            level, and they address issues of public interest, and they may contain some argumentation. Readers at the 
            Advanced Mid level have a very broad vocabulary and can comprehend the main ideas and the factual details of 
            texts. Typically, strong students beyond fourth-year Russian can attempt texts at this level."""
                ]

            _ ->
                []

    else
        []



-- SHARED


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
