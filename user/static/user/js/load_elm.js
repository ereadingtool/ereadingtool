(function () {
    "use strict";
    var node = document.getElementsByClassName("content")[0];

    var app = Elm.Main.embed(node, {
        csrftoken: document.getElementsByName("csrfmiddlewaretoken")[0].value
    });

}());