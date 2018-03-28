(function () {
    "use strict";
    var node = document.getElementsByClassName("content")[0];
    var app = Elm.Main.embed(node);

    function selectAllText(elem_id) {
        var input = document.getElementById(elem_id);

        if (input) {
            input.focus();
            input.setSelectionRange(0, -1);
        }
    }

    // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
    app.ports.selectAllInputText.subscribe(function (elem_id) {
        window.requestAnimationFrame(function (timestamp) {
            selectAllText(elem_id);
        });
    });
}());

