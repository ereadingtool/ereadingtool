module User.Instructor.View exposing (view_instructor_profile_header)

import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class, classList, id)
import Html.Events exposing (onClick)
import Menu.Msg exposing (Msg(..))
import User.Instructor.Profile as InstructorProfile exposing (InstructorProfile)


view_instructor_profile_link : InstructorProfile -> (Msg -> msg) -> Html msg
view_instructor_profile_link instructor_profile top_level_msg =
    div [ class "profile_dropdown_menu" ]
        [ div []
            [ Html.a
                [ attribute "href" (InstructorProfile.profileUriToString instructor_profile)
                ]
                [ Html.text (InstructorProfile.usernameToString (InstructorProfile.username instructor_profile)) ]
            ]
        , div [ classList [ ( "profile_dropdown_menu_overlay", True ) ] ]
            [ div
                [ class "profile_dropdown_menu_item"
                , onClick (top_level_msg <| InstructorLogout instructor_profile)
                ]
                [ Html.text "Logout"
                ]
            ]
        ]


view_instructor_profile_header : InstructorProfile -> (Msg -> msg) -> List (Html msg)
view_instructor_profile_header instructor_profile top_level_msg =
    [ div [ id "profile-link", classList [ ( "menu_item", True ) ] ]
        [ view_instructor_profile_link instructor_profile top_level_msg
        ]
    ]
