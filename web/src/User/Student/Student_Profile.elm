module User.Student.Student_Profile exposing
    ( init
    , main
    , subscriptions
    , view
    , view_content
    )

import Dict
import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, classList)
import Menu.Items
import User.Student.Profile as StudentProfile
import User.Student.Profile.Flags exposing (Flags)
import User.Student.Profile.Help as StudentProfileHelp
import User.Student.Profile.Model as StudentProfileModel exposing (..)
import User.Student.Profile.Msg exposing (Msg)
import User.Student.Profile.Update as StudentProfileUpdate
import User.Student.Profile.View as StudentProfileView
import Views


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        student_help =
            StudentProfileHelp.init

        student_profile =
            StudentProfile.initProfile flags.student_profile
    in
    ( { flags = flags
      , student_endpoints = StudentProfileModel.flagsToEndpoints flags
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
    , StudentProfileHelp.scrollToFirstMsg student_help
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = StudentProfileUpdate.update
        }


view_content : Model -> Html Msg
view_content model =
    div [ classList [ ( "profile", True ) ] ]
        [ div [ classList [ ( "profile_items", True ) ] ]
            [ StudentProfileView.view_preferred_difficulty model
            , StudentProfileView.view_username model
            , StudentProfileView.view_user_email model
            , StudentProfileView.view_student_performance model
            , StudentProfileView.view_feedback_links model
            , StudentProfileView.view_flashcards model
            , StudentProfileView.view_research_consent model
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
        [ StudentProfileView.view_header model Logout { next = NextHelp, prev = PrevHelp, close = CloseHelp }
        , view_content model
        , Views.view_footer
        ]
