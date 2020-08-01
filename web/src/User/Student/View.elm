module User.Student.View exposing
    ( view_profile_dropdown_menu
    , view_student_profile_header
    , view_student_profile_logout_link
    )

import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick)
import Menu.Msg exposing (Msg(..))
import User.Student.Profile as StudentProfile exposing (StudentProfile)
import User.Student.Resource as StudentResource


view_student_profile_page_link : StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_student_profile_page_link student_profile _ =
    let
        display_name =
            case StudentProfile.studentUserName student_profile of
                Just username ->
                    StudentProfile.studentUserNameToString username

                Nothing ->
                    StudentResource.studentEmailToString (StudentProfile.studentEmail student_profile)
    in
    div []
        [ Html.a [ attribute "href" (StudentProfile.profileUriToString student_profile) ]
            [ Html.text display_name
            ]
        ]


view_student_profile_logout_link : StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_student_profile_logout_link student_profile top_level_menu_msg =
    div [ classList [ ( "profile_dropdown_menu_overlay", True ) ] ]
        [ div [ class "profile_dropdown_menu_item", onClick (top_level_menu_msg <| StudentLogout student_profile) ]
            [ Html.text "Logout"
            ]
        ]


view_profile_dropdown_menu : StudentProfile -> (Menu.Msg.Msg -> msg) -> List (Html msg) -> Html msg
view_profile_dropdown_menu _ _ items =
    div [ id "profile-link", classList [ ( "menu_item", True ) ] ]
        [ div [ class "profile_dropdown_menu" ] items
        ]


view_profile_link : StudentProfile -> (Menu.Msg.Msg -> msg) -> Html msg
view_profile_link student_profile top_level_msg =
    let
        items =
            [ view_student_profile_page_link student_profile top_level_msg
            , view_student_profile_logout_link student_profile top_level_msg
            ]
    in
    view_profile_dropdown_menu student_profile top_level_msg items


view_student_profile_header : StudentProfile -> (Menu.Msg.Msg -> msg) -> List (Html msg)
view_student_profile_header student_profile top_level_menu_msg =
    [ view_profile_link student_profile top_level_menu_msg
    ]
