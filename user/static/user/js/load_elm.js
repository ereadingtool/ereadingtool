(function () {
    "use strict";
    var node = document.getElementsByClassName("content")[0];
    var profile = document.getElementById("profile_id");

    var app = Elm.Main.embed(node, {
        csrftoken: document.getElementsByName("csrfmiddlewaretoken")[0].value,

        profile_id: parseInt(profile.value, 10),
        profile_type: profile.dataset.type
    });

}());