(function () {
    "use strict";
    var node = document.getElementsByClassName("content")[0];
    var profile = document.getElementById("profile_id");

    var profile_id = null;
    var profile_type = null;

    if (! profile.value == "") { profile_id = parseInt(profile.value, 10);}
    if (! profile.dataset.type == "") { profile_type = profile.dataset.type;}

    var app = Elm.Main.embed(node, {
        csrftoken: document.getElementsByName("csrfmiddlewaretoken")[0].value,

        profile_id: profile_id,
        profile_type: profile_type
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

    // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
    app.ports.ckEditor.subscribe(function (elem_id) {
        window.requestAnimationFrame(function (timestamp) {
            if (CKEDITOR) {
                CKEDITOR.inline(elem_id).on("change", function (evt) {
                    app.ports.ckEditorUpdate.send(evt.editor.getData());
                });
            }
        });
    });


}());

