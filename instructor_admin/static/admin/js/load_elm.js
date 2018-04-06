(function () {
    "use strict";
    var node = document.getElementsByClassName("content")[0];
    var app = Elm.Main.embed(node, {
        csrftoken: document.getElementsByName("csrfmiddlewaretoken")[0].value
    });

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

    // taken from: https://docs.djangoproject.com/en/2.0/ref/csrf/#acquiring-the-token-if-csrf-use-sessions-is-false
    function getCookie (name) {
        var cookieValue = null;
        if (document.cookie && document.cookie !== "") {
            var cookies = document.cookie.split(";");
            for (var i = 0; i < cookies.length; i++) {
                var cookie = cookies[i];
                // Does this cookie string begin with the name we want?
                if (cookie.substring(0, name.length + 1) === (name + "=")) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }

}());

