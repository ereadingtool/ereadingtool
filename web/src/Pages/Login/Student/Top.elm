module Login.Student.Top exposing
    ( Flags
    , view
    , view_acknowledgements_and_about_links
    , view_content
    , view_help_msgs
    )

import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList, id)
import User.Login
import User
import User.Flags.UnAuthed exposing (UnAuthedUserFlags)
import Views

import Shared

import Spa.Page as Page exposing (Page)



type alias Flags =
    UnAuthedUserFlags {}


view_help_msgs : User.Login.Model -> List (Html User.Login.Msg)
view_help_msgs _ =
    [ div [ class "help_msgs" ]
        [ Html.text """When signing in, please note that this website is not connected to your university’s user account.
    If this is your first time using this website, please create a new account."""
        ]
    ]


view_acknowledgements_and_about_links : User.Login.Model -> Html User.Login.Msg
view_acknowledgements_and_about_links model =
    div [ id "acknowledgements-and-about" ]
        [ div []
            [ Html.a [ attribute "href" (User.urlToString (User.aboutPageURL model.about_page_url)) ]
                [ Html.text "About This Website"
                ]
            ]
        , div []
            [ Html.a [ attribute "href" (User.urlToString (User.acknowledgePageURL model.acknowledgements_page_url)) ]
                [ Html.text "Acknowledgements"
                ]
            ]
        ]


view_content : User.Login.Model -> Html User.Login.Msg
view_content model =
    div [ classList [ ( "login", True ) ] ]
        [ div [ class "login_type" ] [ Html.text (User.Login.label model.login) ]
        , div [ classList [ ( "login_box", True ) ] ] <|
            User.Login.view_email_input model
                ++ User.Login.view_password_input model
                ++ User.Login.view_login model.login
                ++ User.Login.view_submit model
                ++ view_help_msgs model
                ++ [ view_acknowledgements_and_about_links model ]
                ++ User.Login.view_errors model
        ]


view : User.Login.Model -> Html User.Login.Msg
view model =
    div []
        [ Views.view_unauthed_header
        , view_content model
        , Views.view_footer
        ]

save : User.Login.Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> User.Login.Model -> ( User.Login.Model, Cmd User.Login.Msg )
load shared safeModel =
    ( safeModel, Cmd.none )


page : Program Flags User.Login.Model User.Login.Msg
page =
    Page.application
    { init = User.Login.init
    , update = User.Login.update
    , subscriptions = User.Login.subscriptions
    , view = view
    , save = save
    , load = load
    }
