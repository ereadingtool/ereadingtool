module Api.WebSocket exposing
    ( WebSocketCmd(..)
    , WebSocketMsg(..)
    , decodeMsg
    , encodeCmd
    , receive
    , send
    , Address, flashcards, textReader, unwrap
    )

{-| NOTE: We modified this package:<https://github.com/bburdette/websocket> and adapted it
so that Send receieves a Value instead of a String for content. This allows us to encode
the content separately without double encoding issues.

The original package is provided provided under a BSD-3 license and as such, here is the
required disclosure of the original license and copyright notice:

---

BSD 3-Clause License

Copyright (c) 2019, bburdette
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

3.  Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

This WebSocket Elm module lets you encode and decode messages to pass to javascript,
where the actual websocket sending and receiving will take place. See the README for more.

@docs WebSocketCmd
@docs WebSocketMsg
@docs decodeMsg
@docs encodeCmd
@docs receive
@docs send

-}

import Json.Decode as JD
import Json.Encode as JE
import Role exposing (Role(..))
import Url.Builder exposing (QueryParameter)


type Address
    = Address String


unwrap : Address -> String
unwrap (Address val) =
    val


url : String -> List String -> List QueryParameter -> Address
url baseUrl paths queryParams =
    Url.Builder.crossOrigin baseUrl
        paths
        queryParams
        |> Address


textReader : String -> Role -> Int -> Address
textReader baseUrl role textId =
    case role of
        Student ->
            url baseUrl [ "student", "text_read", String.fromInt textId ] []

        Instructor ->
            url baseUrl [ "instructor", "text_read", String.fromInt textId ] []


flashcards : String -> Role -> Address
flashcards baseUrl role =
    case role of
        Student ->
            url baseUrl [ "student", "flashcards" ] []

        Instructor ->
            url baseUrl [ "instructor", "flashcards" ] []


{-| use send to make a websocket convenience function,
like so:

      port sendSocketCommand : JE.Value -> Cmd msg

      wssend =
          WebSocket.send sendSocketCommand

then you can call (makes a Cmd):

      wssend <|
          WebSocket.Send
              { name = "touchpage"
              , content = dta
              }

-}
send : (JE.Value -> Cmd msg) -> WebSocketCmd -> Cmd msg
send portfn wsc =
    portfn (encodeCmd wsc)


{-| make a subscription function with receive and a port, like so:

      port receiveSocketMsg : (JD.Value -> msg) -> Sub msg

      wsreceive =
          receiveSocketMsg <| WebSocket.receive WsMsg

Where WsMessage is defined in your app like this:

      type Msg
          = WsMsg (Result JD.Error WebSocket.WebSocketMsg)
          | <other message types>

then in your application subscriptions:

      subscriptions =
          \_ -> wsreceive

-}
receive : (Result JD.Error WebSocketMsg -> msg) -> (JD.Value -> msg)
receive wsmMsg =
    \v ->
        JD.decodeValue decodeMsg v
            |> wsmMsg


{-| WebSocketCmds go from from elm out to javascript to be processed.

  - name: You should give each websocket connection a unique name.
  - address: is the websocket address, for instance "<ws://127.0.0.1:9000">.
  - protocol: is an extra string to help the server know what kind of data to expect, like
    if your server handled either json or binary data. Probably you can just pass it "".
  - content: the data you're sending through the socket.

-}
type WebSocketCmd
    = Connect { name : String, address : String, protocol : String }
    | Send { name : String, content : JE.Value }
    | Close { name : String }
    | CloseAll


{-| WebSocketMsgs are responses from javascript to elm after websocket operations.
The name should be the same string you used in Connect.
-}
type WebSocketMsg
    = Error { name : String, error : String }
    | Data { name : String, data : String }


{-| encode websocket commands into json.
-}
encodeCmd : WebSocketCmd -> JE.Value
encodeCmd wsc =
    case wsc of
        Connect msg ->
            JE.object
                [ ( "cmd", JE.string "connect" )
                , ( "name", JE.string msg.name )
                , ( "address", JE.string msg.address )
                , ( "protocol", JE.string msg.protocol )
                ]

        Send msg ->
            JE.object
                [ ( "cmd", JE.string "send" )
                , ( "name", JE.string msg.name )
                , ( "content", msg.content )
                ]

        Close msg ->
            JE.object
                [ ( "cmd", JE.string "close" )
                , ( "name", JE.string msg.name )
                ]

        CloseAll ->
            JE.object
                [ ( "cmd", JE.string "closeAll" ) ]


{-| decode incoming messages from the websocket javascript.
-}
decodeMsg : JD.Decoder WebSocketMsg
decodeMsg =
    JD.field "msg" JD.string
        |> JD.andThen
            (\msg ->
                case msg of
                    "error" ->
                        JD.map2 (\a b -> Error { name = a, error = b })
                            (JD.field "name" JD.string)
                            (JD.field "error" JD.string)

                    "data" ->
                        JD.map2 (\a b -> Data { name = a, data = b })
                            (JD.field "name" JD.string)
                            (JD.field "data" JD.string)

                    unk ->
                        JD.fail <| "unknown websocketmsg type: " ++ unk
            )
