port module Ports exposing
    ( CKEditorID
    , CKEditorText
    , addClassToCKEditor
    , ckEditor
    , ckEditorSetHtml
    , ckEditorUpdate
    , clearInputText
    , confirm
    , confirmation
    , scrollTo
    , selectAllInputText
    )


port selectAllInputText : String -> Cmd msg


port clearInputText : String -> Cmd msg


port ckEditor : String -> Cmd msg


type alias CKEditorID =
    String


type alias CKEditorText =
    String


port ckEditorUpdate : (( CKEditorID, CKEditorText ) -> msg) -> Sub msg


port ckEditorSetHtml : ( CKEditorID, String ) -> Cmd msg


port addClassToCKEditor : ( String, String ) -> Cmd msg


port confirm : String -> Cmd msg


port confirmation : (Bool -> msg) -> Sub msg


port redirect : String -> Cmd msg


port scrollTo : String -> Cmd msg


port selectedText : (Maybe String -> msg) -> Sub msg
