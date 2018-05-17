port module Ports exposing (..)

port selectAllInputText : String -> Cmd msg
port ckEditor : String -> Cmd msg

type alias CKEditorID = String
type alias CKEditorText = String

port ckEditorUpdate : ((CKEditorID, CKEditorText) -> msg) -> Sub msg