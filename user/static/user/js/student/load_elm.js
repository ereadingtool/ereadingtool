(function () {
    "use strict";
    var node = document.getElementsByClassName("content")[0];

    var profile_id = null;
    var profile_type = null;

    if (! profile.value == "") { profile_id = parseInt(profile.value, 10);}
    if (! profile.dataset.type == "") { profile_type = profile.dataset.type;}

    var app = Elm.Main.embed(node, {
        csrftoken: document.getElementsByName("csrfmiddlewaretoken")[0].value,
        difficulties: JSON.parse(document.getElementById("difficulty_choices").value),

        profile_id: profile_id,
        profile_type: profile_type
    });

}());