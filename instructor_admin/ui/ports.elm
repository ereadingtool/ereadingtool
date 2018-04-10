port module Ports exposing (..)

port selectAllInputText : String -> Cmd msg
port ckEditor : String -> Cmd msg

port ckEditorUpdate : (String -> msg) -> Sub msg