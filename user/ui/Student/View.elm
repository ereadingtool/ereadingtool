module Student.View exposing
    ( view_profile_dropdown_menu
    , view_student_profile_header
    , view_student_profile_logout_link
    )

import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick)
import Menu.Msg exposing (Msg(..))
import Student.Profile


view_student_profile_page_link : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_student_profile_page_link student_profile top_level_menu_msg =
    let
        display_name =
            case Student.Profile.studentUserName student_profile of
                Just username ->
                    Student.Profile.studentUserNameToString username

                Nothing ->
                    Student.Profile.studentEmailToString (Student.Profile.studentEmail student_profile)
    in
    div []
        [ Html.a [ attribute "href" (Student.Profile.profileUriToString student_profile) ]
            [ Html.text display_name
            ]
        ]


view_student_profile_logout_link : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_student_profile_logout_link student_profile top_level_menu_msg =
    div [ classList [ ( "profile_dropdown_menu_overlay", True ) ] ]
        [ div [ class "profile_dropdown_menu_item", onClick (top_level_menu_msg <| StudentLogout student_profile) ]
            [ Html.text "Logout"
            ]
        ]


view_profile_dropdown_menu : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> List (Html msg) -> Html msg
view_profile_dropdown_menu student_profile top_level_msg items =
    div [ id "profile-link", classList [ ( "menu_item", True ) ] ]
        [ div [ class "profile_dropdown_menu" ] items
        ]


view_profile_link : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_profile_link student_profile top_level_msg =
    let
        items =
            [ view_student_profile_page_link student_profile top_level_msg
            , view_student_profile_logout_link student_profile top_level_msg
            ]
    in
    view_profile_dropdown_menu student_profile top_level_msg items


view_student_profile_header : Student.Profile.StudentProfile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_student_profile_header student_profile top_level_menu_msg =
    [ view_profile_link student_profile top_level_menu_msg
    ]
