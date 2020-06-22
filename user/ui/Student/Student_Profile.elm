module Student.Student_Profile exposing
    ( init
    , main
    , subscriptions
    , view
    , view_content
    )

import Dict exposing (Dict)
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, id)
import Menu.Items
import Student.Profile exposing (StudentProfileParams)
import Student.Profile.Flags exposing (Flags)
import Student.Profile.Help
import Student.Profile.Model exposing (..)
import Student.Profile.Msg exposing (..)
import Student.Profile.Update
import Student.Profile.View
import Views


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        student_help =
            Student.Profile.Help.init

        student_profile =
            Student.Profile.initProfile flags.student_profile
    in
    ( { flags = flags
      , student_endpoints = Student.Profile.Model.flagsToEndpoints flags
      , profile = student_profile
      , menu_items = Menu.Items.initMenuItems flags
      , flashcards = flags.flashcards
      , performance_report = flags.performance_report
      , consenting_to_research = flags.consenting_to_research
      , editing = Dict.empty
      , username_update = { username = Nothing, valid = Nothing, msg = Nothing }
      , help = student_help
      , err_str = ""
      , errors = Dict.empty
      }
    , Student.Profile.Help.scrollToFirstMsg student_help
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = Student.Profile.Update.update
        }


view_content : Model -> Html Msg
view_content model =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ classList [ ( "profile_items", True ) ] ]
            [ Student.Profile.View.view_preferred_difficulty model
            , Student.Profile.View.view_username model
            , Student.Profile.View.view_user_email model
            , Student.Profile.View.view_student_performance model
            , Student.Profile.View.view_feedback_links model
            , Student.Profile.View.view_flashcards model
            , Student.Profile.View.view_research_consent model
            , if not (String.isEmpty model.err_str) then
                span [ attribute "class" "error" ] [ Html.text "error: ", Html.text model.err_str ]

              else
                Html.text ""
            ]
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Student.Profile.View.view_header model Logout { next = NextHelp, prev = PrevHelp, close = CloseHelp }
        , view_content model
        , Views.view_footer
        ]
