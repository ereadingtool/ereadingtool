const mySockets = {};

function sendSocketCommand(wat) {
    "use strict";

    // console.log( "ssc: " +  JSON.stringify(wat, null, 4));
    if (wat.cmd === "connect") {
        // console.log("connecting!");
        let socket = new WebSocket(wat.address, wat.protocol);

        socket.onmessage = function (event) {
            // console.log( "onmessage: " +  JSON.stringify(event.data, null, 4));
            app.ports.receiveSocketMsg.send({
                name: wat.name,
                msg: "data",
                data: event.data
            });
        };

        mySockets[wat.name] = socket;
    } else if (wat.cmd === "send") {
        // console.log("sending to socket: " + wat.name );
        mySockets[wat.name].send(wat.content);
    } else if (wat.cmd === "close") {
        // console.log("closing socket: " + wat.name);
        mySockets[wat.name].close();
        delete mySockets[wat.name];
    }
}